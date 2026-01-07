DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

net.Receive(NET.PersonNotesRequest, function(len, ply)
    if not DDRPT:HasAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "listPeople") then return end

    local steamid64 = net.ReadString()
    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.PeopleNotes
    local offset = (page - 1) * limit

    local where = "steamid64='" .. DB:Escape(steamid64) .. "'"
    if not DDRPT:HasPermission(ply, "canViewSecretNote") then
        where = where .. " AND is_secret=0"
    end

    local countSql = "SELECT COUNT(*) as total FROM ddr_person_notes WHERE " .. where
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_person_notes WHERE %s ORDER BY created_at DESC LIMIT %d OFFSET %d", where, limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.PersonNotesResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.PersonNoteCreateRequest, function(len, ply)
    if not DDRPT:HasAccess(ply) then return end
    if not DDRPT:CheckRate(ply, "addPersonNote") then return end

    local payload = net.ReadTable() or {}
    if payload.is_secret and not DDRPT:HasPermission(ply, "canAddSecretNote") then
        return
    end
    if not payload.note or payload.note == "" then return end

    local sql = string.format(
        "INSERT INTO ddr_person_notes (steamid64, person_name, note, is_secret, author, author_steamid64, created_at, team_snapshot, tags) VALUES ('%s','%s','%s',%d,'%s','%s','%s','%s','%s')",
        DB:Escape(payload.steamid64 or ""),
        DB:Escape(payload.person_name or "Unbekannt"),
        DB:Escape(payload.note),
        payload.is_secret and 1 or 0,
        DB:Escape(ply:Nick()),
        DB:Escape(ply:SteamID64()),
        now(),
        DB:Escape(team.GetName(ply:Team()) or ""),
        DB:Escape(util.TableToJSON(payload.tags or {}))
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        DDRPT:Notify(ply, "Notiz gespeichert.")
    end)
end)
