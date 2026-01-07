DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function refreshBolos()
    local sql = "SELECT * FROM ddr_bolos WHERE active=1 AND (expires_at IS NULL OR expires_at >= NOW())"
    DB:Query(sql, function(ok, rows)
        if not ok then return end
        DDRPT.ActiveBolos = rows or {}
    end)
end

hook.Add("DDRPT_DB_Connected", "DDRPT_LoadBolos", function()
    refreshBolos()
    timer.Create("DDRPT_BoloRefresh", 300, 0, refreshBolos)
end)

net.Receive(NET.BoloListRequest, function(len, ply)
    if not DDRPT:HasAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "listBolos") then return end

    local search = net.ReadString()
    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Bolos
    local offset = (page - 1) * limit

    local where = "active=1"
    if search and search ~= "" then
        where = where .. " AND target_name LIKE '%" .. DB:Escape(search) .. "%'"
    end
    local countSql = "SELECT COUNT(*) as total FROM ddr_bolos WHERE " .. where
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_bolos WHERE %s ORDER BY created_at DESC LIMIT %d OFFSET %d", where, limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.BoloListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.BoloCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canCreateBolo") then return end
    if not DDRPT:CheckRate(ply, "createBolo") then return end

    local payload = net.ReadTable() or {}
    if not payload.target_name or payload.target_name == "" then
        DDRPT:Notify(ply, "Ziel erforderlich.")
        return
    end

    local expiresAt = payload.expires_at or ""
    if expiresAt == "" then
        expiresAt = "NULL"
    else
        expiresAt = "'" .. DB:Escape(expiresAt) .. "'"
    end

    local sql = string.format(
        "INSERT INTO ddr_bolos (target_name, target_steamid64, reason, danger, expires_at, created_by, created_at, updated_at, active) VALUES ('%s','%s','%s','%s',%s,'%s','%s','%s',1)",
        DB:Escape(payload.target_name),
        DB:Escape(payload.target_steamid64 or ""),
        DB:Escape(payload.reason or ""),
        DB:Escape(payload.danger or DDRPT.Config.BoloDangerLevels[1]),
        expiresAt,
        DB:Escape(ply:SteamID64()),
        now(),
        now()
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        refreshBolos()
        DDRPT:Notify(ply, "Fahndung erstellt.")
    end)
end)

local function findBoloBySteamID(steamid64)
    if not DDRPT.ActiveBolos then return nil end
    for _, bolo in ipairs(DDRPT.ActiveBolos) do
        if bolo.target_steamid64 ~= "" and bolo.target_steamid64 == steamid64 then
            return bolo
        end
    end
    return nil
end

hook.Add("PlayerSpawn", "DDRPT_BoloSpawnNotify", function(ply)
    if not DDRPT.Config.Notifications.BoloSpawnNotice then return end
    local bolo = findBoloBySteamID(ply:SteamID64())
    if not bolo then return end

    ply.DDRPT_LastBolo = ply.DDRPT_LastBolo or 0
    if CurTime() - ply.DDRPT_LastBolo < DDRPT.Config.Notifications.BoloSpawnCooldown then return end
    ply.DDRPT_LastBolo = CurTime()

    for _, target in ipairs(player.GetAll()) do
        if DDRPT:HasAccess(target) then
            DDRPT:Notify(target, "Fahndung aktiv: " .. bolo.target_name)
        end
    end
end)
