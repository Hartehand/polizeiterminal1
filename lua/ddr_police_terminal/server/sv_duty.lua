DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

net.Receive(NET.DutyListRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageDutyLog") then return end
    if not DDRPT:CheckRate(ply, "listDuty") then return end

    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Duty
    local offset = (page - 1) * limit

    local countSql = "SELECT COUNT(*) as total FROM ddr_duty_log"
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_duty_log ORDER BY created_at DESC LIMIT %d OFFSET %d", limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.DutyListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.DutyCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageDutyLog") then return end
    if not DDRPT:CheckRate(ply, "createDuty") then return end

    local payload = net.ReadTable() or {}
    if not payload.entry_type or payload.entry_type == "" then
        DDRPT:Notify(ply, "Eintragstyp erforderlich.")
        return
    end
    if not payload.content or payload.content == "" then
        DDRPT:Notify(ply, "Inhalt erforderlich.")
        return
    end

    local sql = string.format(
        "INSERT INTO ddr_duty_log (officer, officer_steamid64, entry_type, content, created_at, supervisor_note) VALUES ('%s','%s','%s','%s','%s','%s')",
        DB:Escape(ply:Nick()),
        DB:Escape(ply:SteamID64()),
        DB:Escape(payload.entry_type),
        DB:Escape(payload.content),
        now(),
        DB:Escape(payload.supervisor_note or "")
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        DDRPT:Notify(ply, "Dienstbuch-Eintrag gespeichert.")
    end)
end)
