DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

net.Receive(NET.IncarcerationListRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageIncarcerations") then return end
    if not DDRPT:CheckRate(ply, "listIncarcerations") then return end

    local search = net.ReadString()
    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Incarcerations
    local offset = (page - 1) * limit

    local where = "1=1"
    if search and search ~= "" then
        if string.match(search, "^%d+$") then
            where = "id=" .. tonumber(search)
        else
            where = "subject_name LIKE '%" .. DB:Escape(search) .. "%' OR reason LIKE '%" .. DB:Escape(search) .. "%'"
        end
    end
    local countSql = "SELECT COUNT(*) as total FROM ddr_incarcerations WHERE " .. where
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_incarcerations WHERE %s ORDER BY created_at DESC LIMIT %d OFFSET %d", where, limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.IncarcerationListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.IncarcerationCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageIncarcerations") then return end
    if not DDRPT:CheckRate(ply, "createIncarcerations") then return end

    local payload = net.ReadTable() or {}
    if not payload.subject_name or payload.subject_name == "" then
        DDRPT:Notify(ply, "Person erforderlich.")
        return
    end
    if not payload.reason or payload.reason == "" then
        DDRPT:Notify(ply, "Grund erforderlich.")
        return
    end
    if not payload.duration_minutes or payload.duration_minutes <= 0 then
        DDRPT:Notify(ply, "Dauer erforderlich.")
        return
    end

    local officers = util.TableToJSON(payload.officers or {})

    local sql = string.format(
        "INSERT INTO ddr_incarcerations (subject_name, reason, duration_minutes, case_id, report_id, officers, created_by, created_at) VALUES ('%s','%s',%d,%s,%s,'%s','%s','%s')",
        DB:Escape(payload.subject_name),
        DB:Escape(payload.reason),
        tonumber(payload.duration_minutes) or 0,
        payload.case_id and tonumber(payload.case_id) or "NULL",
        payload.report_id and tonumber(payload.report_id) or "NULL",
        DB:Escape(officers),
        DB:Escape(ply:SteamID64()),
        now()
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        DDRPT:Notify(ply, "Inhaftierung gespeichert.")
    end)
end)
