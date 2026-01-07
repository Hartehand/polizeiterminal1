DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

net.Receive(NET.EvidenceListRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageEvidence") then return end
    if not DDRPT:CheckRate(ply, "listEvidence") then return end

    local page = math.max(net.ReadUInt(16), 1)
    local limit = DDRPT.Config.Pagination.Evidence
    local offset = (page - 1) * limit

    local countSql = "SELECT COUNT(*) as total FROM ddr_evidence"
    DB:Query(countSql, function(ok, data)
        if not ok then return end
        local total = tonumber(data[1].total) or 0
        local listSql = string.format("SELECT * FROM ddr_evidence ORDER BY created_at DESC LIMIT %d OFFSET %d", limit, offset)
        DB:Query(listSql, function(okList, rows)
            if not okList then return end
            net.Start(NET.EvidenceListResponse)
            net.WriteUInt(page, 16)
            net.WriteUInt(limit, 16)
            net.WriteUInt(total, 32)
            net.WriteTable(rows or {})
            net.Send(ply)
        end)
    end)
end)

net.Receive(NET.EvidenceCreateRequest, function(len, ply)
    if not DDRPT:HasPermission(ply, "canManageEvidence") then return end
    if not DDRPT:CheckRate(ply, "createEvidence") then return end

    local payload = net.ReadTable() or {}
    if not payload.evidence_type or payload.evidence_type == "" then
        DDRPT:Notify(ply, "Beweistyp erforderlich.")
        return
    end
    if not payload.description or payload.description == "" then
        DDRPT:Notify(ply, "Beschreibung erforderlich.")
        return
    end

    local sql = string.format(
        "INSERT INTO ddr_evidence (evidence_type, description, related_report, related_case, storage_location, created_by, created_at) VALUES ('%s','%s',%s,%s,'%s','%s','%s')",
        DB:Escape(payload.evidence_type),
        DB:Escape(payload.description),
        payload.related_report and tonumber(payload.related_report) or "NULL",
        payload.related_case and tonumber(payload.related_case) or "NULL",
        DB:Escape(payload.storage_location or ""),
        DB:Escape(ply:SteamID64()),
        now()
    )

    DB:Query(sql, function(ok, _, insertId)
        if not ok then return end
        local custodyNote = payload.custody_note or "Erstaufnahme"
        local custodySql = string.format(
            "INSERT INTO ddr_evidence_custody (evidence_id, holder, note, created_at) VALUES (%d, '%s', '%s', '%s')",
            insertId,
            DB:Escape(ply:Nick()),
            DB:Escape(custodyNote),
            now()
        )
        DB:Query(custodySql)
        DDRPT:Notify(ply, "Beweismittel registriert (ID " .. insertId .. ").")
    end)
end)
