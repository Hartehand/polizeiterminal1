DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildBorderTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Person")
    list:AddColumn("Dokument")
    list:AddColumn("Ergebnis")
    list:AddColumn("Grund")
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
        net.Start(NET.BorderListRequest)
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
        if page * DDRPT.Config.Pagination.Border < total then
            page = page + 1
            requestList()
        end
    end

    net.Receive(NET.BorderListResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            DDRPT.UI.AddListLine(list, row.created_at or "", row.person_name or "", row.document_checked == 1 and "Ja" or "Nein", row.result or "", row.reason or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(110)
    createPanel:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(createPanel)

    local nameEntry = vgui.Create("DTextEntry", createPanel)
    nameEntry:SetPos(8, 8)
    nameEntry:SetSize(160, 22)
    nameEntry:SetPlaceholderText("Person")
    DDRPT.UI.StyleEntry(nameEntry)

    local docCheck = vgui.Create("DCheckBoxLabel", createPanel)
    docCheck:SetPos(180, 10)
    docCheck:SetText("Dokument geprüft")
    DDRPT.UI.StyleLabel(docCheck)
    docCheck:SizeToContents()

    local resultEntry = vgui.Create("DTextEntry", createPanel)
    resultEntry:SetPos(8, 36)
    resultEntry:SetSize(160, 22)
    resultEntry:SetPlaceholderText("Ergebnis")
    DDRPT.UI.StyleEntry(resultEntry)

    local reasonEntry = vgui.Create("DTextEntry", createPanel)
    reasonEntry:SetPos(180, 36)
    reasonEntry:SetSize(280, 60)
    reasonEntry:SetMultiline(true)
    reasonEntry:SetPlaceholderText("Grund")
    DDRPT.UI.StyleEntry(reasonEntry)

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(470, 36)
    createBtn:SetSize(140, 24)
    createBtn:SetText("Eintrag erstellen")
    DDRPT.UI.StyleButton(createBtn)
    createBtn.DoClick = function()
        net.Start(NET.BorderCreateRequest)
        net.WriteTable({
            person_name = nameEntry:GetValue(),
            person_steamid64 = "",
            document_checked = docCheck:GetChecked(),
            result = resultEntry:GetValue(),
            reason = reasonEntry:GetValue(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
