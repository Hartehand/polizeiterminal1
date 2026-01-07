DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildCustomsTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Person")
    list:AddColumn("Herkunft")
    list:AddColumn("Zoll bezahlt")
    list:AddColumn("Erklärung")
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
        net.Start(NET.CustomsListRequest)
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
        if page * DDRPT.Config.Pagination.Customs < total then
            page = page + 1
            requestList()
        end
    end

    net.Receive(NET.CustomsListResponse, function()
        page = net.ReadUInt(16)
        net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            DDRPT.UI.AddListLine(list, row.created_at or "", row.person_name or "", row.origin or "", row.duty_paid == 1 and "Ja" or "Nein", row.declaration or "")
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

    local originEntry = vgui.Create("DTextEntry", createPanel)
    originEntry:SetPos(180, 8)
    originEntry:SetSize(120, 22)
    originEntry:SetPlaceholderText("Herkunft")
    originEntry:SetText("Ost")
    DDRPT.UI.StyleEntry(originEntry)

    local paidCheck = vgui.Create("DCheckBoxLabel", createPanel)
    paidCheck:SetPos(310, 10)
    paidCheck:SetText("Zoll bezahlt")
    DDRPT.UI.StyleLabel(paidCheck)
    paidCheck:SizeToContents()

    local declarationEntry = vgui.Create("DTextEntry", createPanel)
    declarationEntry:SetPos(8, 36)
    declarationEntry:SetSize(360, 60)
    declarationEntry:SetMultiline(true)
    declarationEntry:SetPlaceholderText("Zollerklärung")
    DDRPT.UI.StyleEntry(declarationEntry)

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(380, 36)
    createBtn:SetSize(150, 24)
    createBtn:SetText("Eintrag erstellen")
    DDRPT.UI.StyleButton(createBtn)
    createBtn.DoClick = function()
        net.Start(NET.CustomsCreateRequest)
        net.WriteTable({
            person_name = nameEntry:GetValue(),
            origin = originEntry:GetValue(),
            declaration = declarationEntry:GetValue(),
            duty_paid = paidCheck:GetChecked(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
