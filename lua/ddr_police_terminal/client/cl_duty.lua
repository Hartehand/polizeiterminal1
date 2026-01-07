DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildDutyTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Beamter")
    list:AddColumn("Typ")
    list:AddColumn("Inhalt")
    DDRPT.UI.StyleList(list)

    local page = 1
    local total = 0

    local pagination = vgui.Create("DPanel", panel)
    pagination:Dock(BOTTOM)
    pagination:SetTall(40)
    pagination:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(pagination)

    local pageLabel = vgui.Create("DLabel", pagination)
    pageLabel:SetPos(8, 12)
    pageLabel:SetText("Seite 1")
    pageLabel:SizeToContents()
    DDRPT.UI.StyleLabel(pageLabel)

    local prevBtn = vgui.Create("DButton", pagination)
    prevBtn:SetPos(120, 8)
    prevBtn:SetSize(80, 24)
    prevBtn:SetText("Zurück")
    DDRPT.UI.StyleButton(prevBtn)

    local nextBtn = vgui.Create("DButton", pagination)
    nextBtn:SetPos(210, 8)
    nextBtn:SetSize(80, 24)
    nextBtn:SetText("Weiter")
    DDRPT.UI.StyleButton(nextBtn)

    local function requestList()
        net.Start(NET.DutyListRequest)
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
        if page * DDRPT.Config.Pagination.Duty < total then
            page = page + 1
            requestList()
        end
    end

    net.Receive(NET.DutyListResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            DDRPT.UI.AddListLine(list, row.created_at or "", row.officer or "", row.entry_type or "", row.content or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(100)
    createPanel:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(createPanel)

    DDRPT.UI.CreateLabel(createPanel, "Typ", 8, 0)
    local typeEntry = vgui.Create("DTextEntry", createPanel)
    typeEntry:SetPos(8, 16)
    typeEntry:SetSize(160, 22)
    typeEntry:SetPlaceholderText("Typ (Schichtbeginn)")
    DDRPT.UI.StyleEntry(typeEntry)

    DDRPT.UI.CreateLabel(createPanel, "Inhalt", 8, 40)
    local contentEntry = vgui.Create("DTextEntry", createPanel)
    contentEntry:SetPos(8, 56)
    contentEntry:SetSize(400, 50)
    contentEntry:SetMultiline(true)
    contentEntry:SetPlaceholderText("Inhalt")
    DDRPT.UI.StyleEntry(contentEntry)

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(420, 56)
    createBtn:SetSize(150, 24)
    createBtn:SetText("Eintrag erstellen")
    DDRPT.UI.StyleButton(createBtn)
    createBtn.DoClick = function()
        net.Start(NET.DutyCreateRequest)
        net.WriteTable({
            entry_type = typeEntry:GetValue(),
            content = contentEntry:GetValue(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
