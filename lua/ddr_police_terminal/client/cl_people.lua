DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildPeopleTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local searchPanel = vgui.Create("DPanel", panel)
    searchPanel:Dock(TOP)
    searchPanel:SetTall(50)
    searchPanel:DockMargin(0, 0, 0, 8)
    DDRPT.UI.ApplyPanelStyle(searchPanel)

    local nameEntry = vgui.Create("DTextEntry", searchPanel)
    nameEntry:SetPos(8, 12)
    nameEntry:SetSize(200, 22)
    nameEntry:SetPlaceholderText("Name")
    DDRPT.UI.StyleEntry(nameEntry)

    local searchBtn = vgui.Create("DButton", searchPanel)
    searchBtn:SetPos(220, 12)
    searchBtn:SetSize(100, 22)
    searchBtn:SetText("Suchen")
    DDRPT.UI.StyleButton(searchBtn)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Autor")
    list:AddColumn("Geheim")
    list:AddColumn("Notiz")
    DDRPT.UI.StyleList(list)

    local page = 1
    local total = 0

    local pageLabel = vgui.Create("DLabel", panel)
    pageLabel:Dock(BOTTOM)
    pageLabel:SetTall(20)
    pageLabel:SetText("Seite 1")
    DDRPT.UI.StyleLabel(pageLabel)

    local function requestList()
        net.Start(NET.PersonNotesRequest)
        net.WriteString(nameEntry:GetValue())
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
            DDRPT.UI.AddListLine(list, row.created_at or "", row.author or "", tostring(row.is_secret == 1), row.note or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(120)
    createPanel:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(createPanel)

    local noteNameEntry = vgui.Create("DTextEntry", createPanel)
    noteNameEntry:SetPos(8, 8)
    noteNameEntry:SetSize(200, 22)
    noteNameEntry:SetPlaceholderText("Name")
    DDRPT.UI.StyleEntry(noteNameEntry)

    local noteEntry = vgui.Create("DTextEntry", createPanel)
    noteEntry:SetPos(8, 36)
    noteEntry:SetSize(460, 60)
    noteEntry:SetMultiline(true)
    noteEntry:SetPlaceholderText("Notiz")
    DDRPT.UI.StyleEntry(noteEntry)

    local secretCheck = vgui.Create("DCheckBoxLabel", createPanel)
    secretCheck:SetPos(480, 36)
    secretCheck:SetText("Geheim")
    DDRPT.UI.StyleLabel(secretCheck)
    secretCheck:SizeToContents()

    local addBtn = vgui.Create("DButton", createPanel)
    addBtn:SetPos(480, 64)
    addBtn:SetSize(120, 28)
    addBtn:SetText("Notiz speichern")
    DDRPT.UI.StyleButton(addBtn)
    addBtn.DoClick = function()
        net.Start(NET.PersonNoteCreateRequest)
        net.WriteTable({
            steamid64 = "",
            person_name = noteNameEntry:GetValue(),
            note = noteEntry:GetValue(),
            is_secret = secretCheck:GetChecked(),
        })
        net.SendToServer()
    end

    return panel
end
