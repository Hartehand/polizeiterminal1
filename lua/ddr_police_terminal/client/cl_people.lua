DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildPeopleTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)

    local searchPanel = vgui.Create("DPanel", panel)
    searchPanel:Dock(TOP)
    searchPanel:SetTall(50)
    searchPanel:DockMargin(0, 0, 0, 8)

    local steamEntry = vgui.Create("DTextEntry", searchPanel)
    steamEntry:SetPos(8, 12)
    steamEntry:SetSize(200, 22)
    steamEntry:SetPlaceholderText("SteamID64")

    local searchBtn = vgui.Create("DButton", searchPanel)
    searchBtn:SetPos(220, 12)
    searchBtn:SetSize(100, 22)
    searchBtn:SetText("Suchen")

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Autor")
    list:AddColumn("Geheim")
    list:AddColumn("Notiz")

    local page = 1
    local total = 0

    local pageLabel = vgui.Create("DLabel", panel)
    pageLabel:Dock(BOTTOM)
    pageLabel:SetTall(20)
    pageLabel:SetText("Seite 1")

    local function requestList()
        net.Start(NET.PersonNotesRequest)
        net.WriteString(steamEntry:GetValue())
        net.WriteUInt(page, 16)
        net.SendToServer()
    end

    searchBtn.DoClick = function()
        page = 1
        requestList()
    end

    net.Receive(NET.PersonNotesResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            list:AddLine(row.created_at or "", row.author or "", tostring(row.is_secret == 1), row.note or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(120)
    createPanel:DockMargin(0, 8, 0, 0)

    local nameEntry = vgui.Create("DTextEntry", createPanel)
    nameEntry:SetPos(8, 8)
    nameEntry:SetSize(200, 22)
    nameEntry:SetPlaceholderText("Name")

    local noteEntry = vgui.Create("DTextEntry", createPanel)
    noteEntry:SetPos(8, 36)
    noteEntry:SetSize(460, 60)
    noteEntry:SetMultiline(true)
    noteEntry:SetPlaceholderText("Notiz")

    local secretCheck = vgui.Create("DCheckBoxLabel", createPanel)
    secretCheck:SetPos(480, 36)
    secretCheck:SetText("Geheim")
    secretCheck:SizeToContents()

    local addBtn = vgui.Create("DButton", createPanel)
    addBtn:SetPos(480, 64)
    addBtn:SetSize(120, 28)
    addBtn:SetText("Notiz speichern")
    addBtn.DoClick = function()
        net.Start(NET.PersonNoteCreateRequest)
        net.WriteTable({
            steamid64 = steamEntry:GetValue(),
            person_name = nameEntry:GetValue(),
            note = noteEntry:GetValue(),
            is_secret = secretCheck:GetChecked(),
        })
        net.SendToServer()
    end

    return panel
end
