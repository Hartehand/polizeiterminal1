DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function log(msg)
    MsgC(Color(120, 200, 255), DDRPT.Config.AddonPrefix .. " ", color_white, msg .. "\n")
end

local function addAudit(reportId, action, actor)
    local sql = string.format(
        "INSERT INTO ddr_report_audit (report_id, action, actor, created_at) VALUES (%d, '%s', '%s', '%s')",
        reportId,
        DB:Escape(action),
        DB:Escape(actor),
        now()
    )
    DB:Query(sql)
end

local function sendList(ply, filters, page)
    local limit = DDRPT.Config.Pagination.Reports
    local offset = (page - 1) * limit
    local where = {"1=1"}

    if filters.status and filters.status ~= "" then
        table.insert(where, "status='" .. DB:Escape(filters.status) .. "'")
    end
    if filters.category and filters.category ~= "" then
        table.insert(where, "category='" .. DB:Escape(filters.category) .. "'")
    end
    if filters.accused and filters.accused ~= "" then
        table.insert(where, "accused_name LIKE '%" .. DB:Escape(filters.accused) .. "%'")
    end
    if filters.report_no and filters.report_no ~= "" then
        table.insert(where, "report_no LIKE '%" .. DB:Escape(filters.report_no) .. "%'")
    end

    local whereSql = table.concat(where, " AND ")
    local listSql = string.format(
        "SELECT id, report_no, category, status, accused_name, priority, created_at FROM ddr_reports WHERE %s ORDER BY created_at DESC LIMIT %d OFFSET %d",
        whereSql, limit, offset
    )
    local countSql = "SELECT COUNT(*) as total FROM ddr_reports WHERE " .. whereSql

    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = 0
        if data and data[1] and data[1].total then
            total = tonumber(data[1].total) or 0
        end
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.ReportListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end

net.Receive(NET.ReportListRequest, function(len, ply)
    if not DDRPT:HasAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "listReports") then return end

    local page = net.ReadUInt(16)
    local filters = net.ReadTable() or {}
    page = math.max(page, 1)
    sendList(ply, filters, page)
end)

net.Receive(NET.ReportCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canCreateReport") then return end
    if not DDRPT:CheckRate(ply, "createReport") then return end

    local payload = net.ReadTable() or {}
    if not payload.description or payload.description == "" then
        DDRPT:Notify(ply, "Beschreibung ist erforderlich.")
        return
    end

    local reporter = payload.reporter or ply:Nick()
    local accused = payload.accused_name or "Unbekannt"
    local accusedSteam = payload.accused_steamid64 or ""
    local category = payload.category or DDRPT.Config.ReportCategories[1]
    local location = payload.location or "Unbekannt"
    local occurredAt = payload.occurred_at or now()
    local description = payload.description
    local witnesses = payload.witnesses or ""
    local evidence = payload.evidence or ""
    local priority = payload.priority or DDRPT.Config.PriorityLevels[1]
    local status = payload.status or DDRPT.Config.ReportStatuses[1]

    local sql = string.format(
        "INSERT INTO ddr_reports (reporter, accused_name, accused_steamid64, category, location, occurred_at, description, witnesses, evidence, priority, status, created_by, assignee, created_at, updated_at) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')",
        DB:Escape(reporter),
        DB:Escape(accused),
        DB:Escape(accusedSteam),
        DB:Escape(category),
        DB:Escape(location),
        DB:Escape(occurredAt),
        DB:Escape(description),
        DB:Escape(witnesses),
        DB:Escape(evidence),
        DB:Escape(priority),
        DB:Escape(status),
        DB:Escape(ply:SteamID64()),
        DB:Escape(payload.assignee or ""),
        now(),
        now()
    )

    DB:Query(sql, function(ok, _, insertId)
        if not ok then return end
        local reportNo = "VP-" .. os.date("%Y%m%d") .. "-" .. string.format("%04d", tonumber(insertId) or 0)
        local updateSql = string.format("UPDATE ddr_reports SET report_no='%s' WHERE id=%d", DB:Escape(reportNo), insertId)
        DB:Query(updateSql)
        addAudit(insertId, "Anzeige erstellt", ply:Nick())

        if DDRPT.Config.Notifications.ReportHighPriorityRadio and priority == "Hoch" then
            for _, target in ipairs(player.GetAll()) do
                if DDRPT:HasAccess(target) then
                    DarkRP.notify(target, 1, 6, "Funkmeldung: Hochprioritäts-Anzeige " .. reportNo)
                end
            end
        end

        DDRPT:Notify(ply, "Anzeige erstellt: " .. reportNo)
    end)
end)

net.Receive(NET.ReportDetailRequest, function(len, ply)
    if not DDRPT:HasAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "reportDetail") then return end
    local reportId = net.ReadUInt(32)

    local sql = "SELECT * FROM ddr_reports WHERE id=" .. tonumber(reportId)
    DB:Query(sql, function(ok, rows)
        if not ok or not rows or not rows[1] then return end
        local report = rows[1]
        local commentsSql = "SELECT * FROM ddr_report_comments WHERE report_id=" .. tonumber(reportId) .. " ORDER BY created_at DESC"
        DB:Query(commentsSql, function(okComments, comments)
            if not okComments then return end
            local auditSql = "SELECT * FROM ddr_report_audit WHERE report_id=" .. tonumber(reportId) .. " ORDER BY created_at DESC"
            DB:Query(auditSql, function(okAudit, audits)
                if not okAudit then return end
                net.Start(NET.ReportDetailResponse)
                net.WriteTable(report)
                net.WriteTable(comments or {})
                net.WriteTable(audits or {})
                net.Send(ply)
            end)
        end)
    end)
end)

net.Receive(NET.ReportUpdateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canEditReport") then return end
    if not DDRPT:CheckRate(ply, "reportUpdate") then return end

    local reportId = net.ReadUInt(32)
    local updates = net.ReadTable() or {}

    local fields = {}
    if updates.status then
        table.insert(fields, "status='" .. DB:Escape(updates.status) .. "'")
    end
    if updates.assignee then
        table.insert(fields, "assignee='" .. DB:Escape(updates.assignee) .. "'")
    end
    if updates.category then
        table.insert(fields, "category='" .. DB:Escape(updates.category) .. "'")
    end
    if updates.description then
        table.insert(fields, "description='" .. DB:Escape(updates.description) .. "'")
    end
    if updates.priority then
        table.insert(fields, "priority='" .. DB:Escape(updates.priority) .. "'")
    end

    if #fields == 0 then return end

    local sql = "UPDATE ddr_reports SET " .. table.concat(fields, ", ") .. ", updated_at='" .. now() .. "' WHERE id=" .. tonumber(reportId)
    DB:Query(sql, function(ok)
        if not ok then return end
        addAudit(reportId, "Anzeige aktualisiert", ply:Nick())
        DDRPT:Notify(ply, "Anzeige aktualisiert.")
    end)
end)

net.Receive(NET.ReportCommentRequest, function(len, ply)
    if not DDRPT:HasAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "addComment") then return end

    local reportId = net.ReadUInt(32)
    local comment = net.ReadString()
    if comment == "" then return end

    local sql = string.format(
        "INSERT INTO ddr_report_comments (report_id, author, author_steamid64, comment, created_at) VALUES (%d, '%s', '%s', '%s', '%s')",
        reportId,
        DB:Escape(ply:Nick()),
        DB:Escape(ply:SteamID64()),
        DB:Escape(comment),
        now()
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        addAudit(reportId, "Kommentar hinzugefügt", ply:Nick())
        DDRPT:Notify(ply, "Kommentar hinzugefügt.")
        net.Start(NET.ReportCommentResponse)
        net.WriteUInt(reportId, 32)
        net.WriteString(comment)
        net.Send(ply)
    end)
end)
