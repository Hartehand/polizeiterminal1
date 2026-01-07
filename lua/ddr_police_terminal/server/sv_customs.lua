DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

net.Receive(NET.CustomsListRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageCustoms") then return end
    if not DDRPT:CheckRate(ply, "listCustoms") then return end

    local search = net.ReadString()
    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Customs
    local offset = (page - 1) * limit

    local where = "1=1"
    if search and search ~= "" then
        where = "person_name LIKE '%" .. DB:Escape(search) .. "%'"
    end
    local countSql = "SELECT COUNT(*) as total FROM ddr_customs WHERE " .. where
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_customs WHERE %s ORDER BY created_at DESC LIMIT %d OFFSET %d", where, limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.CustomsListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.CustomsCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageCustoms") then return end
    if not DDRPT:CheckRate(ply, "createCustoms") then return end

    local payload = net.ReadTable() or {}
    if not payload.person_name or payload.person_name == "" then
        DDRPT:Notify(ply, "Person erforderlich.")
        return
    end
    if not payload.declaration or payload.declaration == "" then
        DDRPT:Notify(ply, "Zollerklärung erforderlich.")
        return
    end

    local sql = string.format(
        "INSERT INTO ddr_customs (person_name, origin, declaration, duty_paid, created_by, created_at) VALUES ('%s','%s','%s',%d,'%s','%s')",
        DB:Escape(payload.person_name),
        DB:Escape(payload.origin or "Ost"),
        DB:Escape(payload.declaration),
        payload.duty_paid and 1 or 0,
        DB:Escape(ply:SteamID64()),
        now()
    )

    DB:Query(sql, function(ok)
        if not ok then return end
        DDRPT:Notify(ply, "Zollerklärung gespeichert.")
    end)
end)
