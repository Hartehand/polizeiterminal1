DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildDutyTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Beamter")
    list:AddColumn("Typ")
    list:AddColumn("Inhalt")

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
            list:AddLine(row.created_at or "", row.officer or "", row.entry_type or "", row.content or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(100)
    createPanel:DockMargin(0, 8, 0, 0)

    local typeEntry = vgui.Create("DTextEntry", createPanel)
    typeEntry:SetPos(8, 8)
    typeEntry:SetSize(160, 22)
    typeEntry:SetPlaceholderText("Typ (Schichtbeginn)")

    local contentEntry = vgui.Create("DTextEntry", createPanel)
    contentEntry:SetPos(8, 36)
    contentEntry:SetSize(400, 50)
    contentEntry:SetMultiline(true)
    contentEntry:SetPlaceholderText("Inhalt")

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(420, 36)
    createBtn:SetSize(150, 24)
    createBtn:SetText("Eintrag erstellen")
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
