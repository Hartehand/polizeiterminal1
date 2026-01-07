DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildEvidenceTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("ID"):SetFixedWidth(40)
    list:AddColumn("Typ")
    list:AddColumn("Beschreibung")
    list:AddColumn("Report")
    list:AddColumn("Case")
    list:AddColumn("Lagerort")

    local page = 1
    local total = 0

    local pagination = vgui.Create("DPanel", panel)
    pagination:Dock(BOTTOM)
    pagination:SetTall(40)
    pagination:DockMargin(0, 8, 0, 0)

    local pageLabel = vgui.Create("DLabel", pagination)
    pageLabel:SetPos(8, 12)
    pageLabel:SetText("Seite 1")
    pageLabel:SizeToContents()

    local prevBtn = vgui.Create("DButton", pagination)
    prevBtn:SetPos(120, 8)
    prevBtn:SetSize(80, 24)
    prevBtn:SetText("Zurück")

    local nextBtn = vgui.Create("DButton", pagination)
    nextBtn:SetPos(210, 8)
    nextBtn:SetSize(80, 24)
    nextBtn:SetText("Weiter")

    local function requestList()
        net.Start(NET.EvidenceListRequest)
        net.WriteUInt(page, 16)
        net.SendToServer()
    end

    prevBtn.DoClick = function()
        if page > 1 then
            page = page - 1
            requestList()
        end
    end

    nextBtn.DoClick = function()
        if page * DDRPT.Config.Pagination.Evidence < total then
            page = page + 1
            requestList()
        end
    end

    net.Receive(NET.EvidenceListResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            list:AddLine(row.id, row.evidence_type or "", row.description or "", row.related_report or "", row.related_case or "", row.storage_location or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(120)
    createPanel:DockMargin(0, 8, 0, 0)

    local typeEntry = vgui.Create("DTextEntry", createPanel)
    typeEntry:SetPos(8, 8)
    typeEntry:SetSize(120, 22)
    typeEntry:SetPlaceholderText("Typ")

    local descEntry = vgui.Create("DTextEntry", createPanel)
    descEntry:SetPos(140, 8)
    descEntry:SetSize(260, 22)
    descEntry:SetPlaceholderText("Beschreibung")

    local reportEntry = vgui.Create("DTextEntry", createPanel)
    reportEntry:SetPos(410, 8)
    reportEntry:SetSize(80, 22)
    reportEntry:SetPlaceholderText("Report")

    local caseEntry = vgui.Create("DTextEntry", createPanel)
    caseEntry:SetPos(500, 8)
    caseEntry:SetSize(80, 22)
    caseEntry:SetPlaceholderText("Case")

    local storageEntry = vgui.Create("DTextEntry", createPanel)
    storageEntry:SetPos(8, 36)
    storageEntry:SetSize(200, 22)
    storageEntry:SetPlaceholderText("Lagerort")

    local custodyEntry = vgui.Create("DTextEntry", createPanel)
    custodyEntry:SetPos(220, 36)
    custodyEntry:SetSize(200, 22)
    custodyEntry:SetPlaceholderText("Custody Note")

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(430, 36)
    createBtn:SetSize(150, 24)
    createBtn:SetText("Beweis anlegen")
    createBtn.DoClick = function()
        net.Start(NET.EvidenceCreateRequest)
        net.WriteTable({
            evidence_type = typeEntry:GetValue(),
            description = descEntry:GetValue(),
            related_report = tonumber(reportEntry:GetValue()) or nil,
            related_case = tonumber(caseEntry:GetValue()) or nil,
            storage_location = storageEntry:GetValue(),
            custody_note = custodyEntry:GetValue(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
