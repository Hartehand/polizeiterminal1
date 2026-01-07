DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function log(msg)
    MsgC(Color(120, 200, 255), DDRPT.Config.AddonPrefix .. " ", color_white, msg .. "\n")
end

net.Receive(NET.CaseListRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageCases") then return end
    if not DDRPT:CheckRate(ply, "listCases") then return end

    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Cases
    local offset = (page - 1) * limit

    local countSql = "SELECT COUNT(*) as total FROM ddr_cases"
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_cases ORDER BY updated_at DESC LIMIT %d OFFSET %d", limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.CaseListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.CaseCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageCases") then return end
    if not DDRPT:CheckRate(ply, "createCase") then return end

    local payload = net.ReadTable() or {}
    if not payload.title or payload.title == "" then
        DDRPT:Notify(ply, "Titel erforderlich.")
        return
    end

    local assignees = util.TableToJSON(payload.assignees or {})
    local people = util.TableToJSON(payload.linked_people or {})
    local evidence = util.TableToJSON(payload.linked_evidence or {})

    local sql = string.format(
        "INSERT INTO ddr_cases (title, description, status, assignees, linked_people, linked_evidence, created_by, created_at, updated_at) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s','%s')",
        DB:Escape(payload.title),
        DB:Escape(payload.description or ""),
        DB:Escape(payload.status or "Neu"),
        DB:Escape(assignees),
        DB:Escape(people),
        DB:Escape(evidence),
        DB:Escape(ply:SteamID64()),
        now(),
        now()
    )

    DB:Query(sql, function(ok, _, insertId)
        if not ok then return end
        if payload.report_links then
            for _, reportId in ipairs(payload.report_links) do
                local linkSql = string.format("INSERT INTO ddr_case_links (case_id, report_id, created_at) VALUES (%d, %d, '%s')", insertId, tonumber(reportId), now())
                DB:Query(linkSql)
            end
        end
        DDRPT:Notify(ply, "Akte erstellt.")
    end)
end)

net.Receive(NET.CaseDetailRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageCases") then return end
    local caseId = net.ReadUInt(32)
    local sql = "SELECT * FROM ddr_cases WHERE id=" .. tonumber(caseId)
    DB:Query(sql, function(ok, rows)
        if not ok or not rows or not rows[1] then return end
        local caseData = rows[1]
        local linksSql = "SELECT report_id FROM ddr_case_links WHERE case_id=" .. tonumber(caseId)
        DB:Query(linksSql, function(okLinks, links)
            if not okLinks then return end
            net.Start(NET.CaseDetailResponse)
            net.WriteTable(caseData)
            net.WriteTable(links or {})
            net.Send(ply)
        end)
    end)
end)
