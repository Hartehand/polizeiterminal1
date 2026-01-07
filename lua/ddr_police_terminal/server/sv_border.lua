DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function hasBorderAccess(ply)
    return DDRPT.Config.BorderAccessTeams[ply:Team()] == true
end

net.Receive(NET.BorderListRequest, function(len, ply)
    if not hasBorderAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "listBorder") then return end

    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Border
    local offset = (page - 1) * limit

    local countSql = "SELECT COUNT(*) as total FROM ddr_border_checks"
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_border_checks ORDER BY created_at DESC LIMIT %d OFFSET %d", limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.BorderListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.BorderCreateRequest, function(len, ply)
    if not hasBorderAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "createBorder") then return end

    local payload = net.ReadTable() or {}
    if not payload.person_name or payload.person_name == "" then
        DDRPT:Notify(ply, "Person erforderlich.")
        return
    end

    local sql = string.format(
        "INSERT INTO ddr_border_checks (person_name, person_steamid64, document_checked, result, reason, created_by, created_at) VALUES ('%s','%s',%d,'%s','%s','%s','%s')",
        DB:Escape(payload.person_name),
        DB:Escape(payload.person_steamid64 or ""),
        payload.document_checked and 1 or 0,
        DB:Escape(payload.result or "durchgelassen"),
        DB:Escape(payload.reason or ""),
        DB:Escape(ply:SteamID64()),
        now()
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        DDRPT:Notify(ply, "Grenzkontroll-Eintrag gespeichert.")
    end)
end)
