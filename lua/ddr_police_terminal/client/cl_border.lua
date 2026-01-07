DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildBorderTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Person")
    list:AddColumn("Dokument")
    list:AddColumn("Ergebnis")
    list:AddColumn("Grund")

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
            list:AddLine(row.created_at or "", row.person_name or "", row.document_checked == 1 and "Ja" or "Nein", row.result or "", row.reason or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(110)
    createPanel:DockMargin(0, 8, 0, 0)

    local nameEntry = vgui.Create("DTextEntry", createPanel)
    nameEntry:SetPos(8, 8)
    nameEntry:SetSize(160, 22)
    nameEntry:SetPlaceholderText("Person")

    local steamEntry = vgui.Create("DTextEntry", createPanel)
    steamEntry:SetPos(180, 8)
    steamEntry:SetSize(160, 22)
    steamEntry:SetPlaceholderText("SteamID64")

    local docCheck = vgui.Create("DCheckBoxLabel", createPanel)
    docCheck:SetPos(350, 10)
    docCheck:SetText("Dokument geprüft")
    docCheck:SizeToContents()

    local resultEntry = vgui.Create("DTextEntry", createPanel)
    resultEntry:SetPos(8, 36)
    resultEntry:SetSize(160, 22)
    resultEntry:SetPlaceholderText("Ergebnis")

    local reasonEntry = vgui.Create("DTextEntry", createPanel)
    reasonEntry:SetPos(180, 36)
    reasonEntry:SetSize(280, 60)
    reasonEntry:SetMultiline(true)
    reasonEntry:SetPlaceholderText("Grund")

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(470, 36)
    createBtn:SetSize(140, 24)
    createBtn:SetText("Eintrag erstellen")
    createBtn.DoClick = function()
        net.Start(NET.BorderCreateRequest)
        net.WriteTable({
            person_name = nameEntry:GetValue(),
            person_steamid64 = steamEntry:GetValue(),
            document_checked = docCheck:GetChecked(),
            result = resultEntry:GetValue(),
            reason = reasonEntry:GetValue(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
