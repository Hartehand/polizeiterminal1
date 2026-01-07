DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildBoloTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("ID"):SetFixedWidth(40)
    list:AddColumn("Ziel")
    list:AddColumn("Gefahr")
    list:AddColumn("Grund")
    list:AddColumn("Ablauf")
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
        net.Start(NET.BoloListRequest)
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
        if page * DDRPT.Config.Pagination.Bolos < total then
            page = page + 1
            requestList()
        end
    end

    net.Receive(NET.BoloListResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            DDRPT.UI.AddListLine(list, row.id, row.target_name or "", row.danger or "", row.reason or "", row.expires_at or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(100)
    createPanel:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(createPanel)

    DDRPT.UI.CreateLabel(createPanel, "Ziel", 8, 0)
    local targetEntry = vgui.Create("DTextEntry", createPanel)
    targetEntry:SetPos(8, 16)
    targetEntry:SetSize(220, 22)
    targetEntry:SetPlaceholderText("Zielname")
    DDRPT.UI.StyleEntry(targetEntry)

    DDRPT.UI.CreateLabel(createPanel, "Gefahrstufe", 240, 0)
    local dangerCombo = vgui.Create("DComboBox", createPanel)
    dangerCombo:SetPos(240, 16)
    dangerCombo:SetSize(120, 22)
    for _, level in ipairs(DDRPT.Config.BoloDangerLevels) do
        dangerCombo:AddChoice(level)
    end
    dangerCombo:SetValue(DDRPT.Config.BoloDangerLevels[1])
    DDRPT.UI.StyleEntry(dangerCombo)

    DDRPT.UI.CreateLabel(createPanel, "Grund", 8, 40)
    local reasonEntry = vgui.Create("DTextEntry", createPanel)
    reasonEntry:SetPos(8, 56)
    reasonEntry:SetSize(400, 50)
    reasonEntry:SetMultiline(true)
    reasonEntry:SetPlaceholderText("Grund")
    DDRPT.UI.StyleEntry(reasonEntry)

    DDRPT.UI.CreateLabel(createPanel, "Ablauf", 420, 40)
    local expiresEntry = vgui.Create("DTextEntry", createPanel)
    expiresEntry:SetPos(420, 56)
    expiresEntry:SetSize(150, 22)
    expiresEntry:SetPlaceholderText("Ablauf (YYYY-MM-DD)")
    DDRPT.UI.StyleEntry(expiresEntry)

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(420, 84)
    createBtn:SetSize(150, 22)
    createBtn:SetText("Fahndung erstellen")
    DDRPT.UI.StyleButton(createBtn)
    createBtn.DoClick = function()
        net.Start(NET.BoloCreateRequest)
        net.WriteTable({
            target_name = targetEntry:GetValue(),
            target_steamid64 = "",
            danger = dangerCombo:GetValue(),
            reason = reasonEntry:GetValue(),
            expires_at = expiresEntry:GetValue(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
