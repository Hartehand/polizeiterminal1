DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildCasesTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("ID"):SetFixedWidth(40)
    list:AddColumn("Titel")
    list:AddColumn("Status")
    list:AddColumn("Aktualisiert")
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
        net.Start(NET.CaseListRequest)
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
        if page * DDRPT.Config.Pagination.Cases < total then
            page = page + 1
            requestList()
        end
    end

    list.OnRowSelected = function(_, _, row)
        local caseId = tonumber(row:GetColumnText(1))
        if not caseId then return end
        net.Start(NET.CaseDetailRequest)
        net.WriteUInt(caseId, 32)
        net.SendToServer()
    end

    net.Receive(NET.CaseListResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            DDRPT.UI.AddListLine(list, row.id, row.title or "", row.status or "", row.updated_at or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    net.Receive(NET.CaseDetailResponse, function()
        local caseData = net.ReadTable() or {}
        local links = net.ReadTable() or {}
        local frame = vgui.Create("DFrame")
        frame:SetSize(600, 420)
        frame:Center()
        frame:SetTitle("Akte " .. (caseData.title or ""))
        frame:MakePopup()
        frame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, DDRPT.UI.Colors.Background)
        end
        local label = vgui.Create("DLabel", frame)
        label:SetPos(12, 40)
        label:SetSize(560, 120)
        label:SetText(string.format("Status: %s\nBeschreibung: %s\nAssignees: %s\nReports: %s",
            caseData.status or "",
            caseData.description or "",
            caseData.assignees or "",
            util.TableToJSON(links or {})
        ))
        DDRPT.UI.StyleLabel(label)

        local statusLabel = vgui.Create("DLabel", frame)
        statusLabel:SetPos(12, 170)
        statusLabel:SetText("Status ändern")
        DDRPT.UI.StyleLabel(statusLabel)
        statusLabel:SizeToContents()

        local statusCombo = vgui.Create("DComboBox", frame)
        statusCombo:SetPos(12, 190)
        statusCombo:SetSize(160, 22)
        for _, status in ipairs(DDRPT.Config.ReportStatuses) do
            statusCombo:AddChoice(status)
        end
        statusCombo:SetValue(caseData.status or "Neu")
        DDRPT.UI.StyleEntry(statusCombo)

        local descEntry = vgui.Create("DTextEntry", frame)
        descEntry:SetPos(12, 220)
        descEntry:SetSize(420, 80)
        descEntry:SetMultiline(true)
        descEntry:SetText(caseData.description or "")
        DDRPT.UI.StyleEntry(descEntry)

        local updateBtn = vgui.Create("DButton", frame)
        updateBtn:SetPos(450, 220)
        updateBtn:SetSize(120, 28)
        updateBtn:SetText("Speichern")
        DDRPT.UI.StyleButton(updateBtn)
        updateBtn.DoClick = function()
            net.Start(NET.CaseUpdateRequest)
            net.WriteUInt(caseData.id or 0, 32)
            net.WriteTable({
                status = statusCombo:GetValue(),
                description = descEntry:GetValue(),
            })
            net.SendToServer()
        end
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(120)
    createPanel:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(createPanel)

    DDRPT.UI.CreateLabel(createPanel, "Titel", 8, 0)
    local titleEntry = vgui.Create("DTextEntry", createPanel)
    titleEntry:SetPos(8, 16)
    titleEntry:SetSize(200, 22)
    titleEntry:SetPlaceholderText("Titel")
    DDRPT.UI.StyleEntry(titleEntry)

    DDRPT.UI.CreateLabel(createPanel, "Status", 220, 0)
    local statusEntry = vgui.Create("DComboBox", createPanel)
    statusEntry:SetPos(220, 16)
    statusEntry:SetSize(140, 22)
    for _, status in ipairs(DDRPT.Config.ReportStatuses) do
        statusEntry:AddChoice(status)
    end
    statusEntry:SetValue("Neu")
    DDRPT.UI.StyleEntry(statusEntry)

    DDRPT.UI.CreateLabel(createPanel, "Beschreibung", 8, 40)
    local descEntry = vgui.Create("DTextEntry", createPanel)
    descEntry:SetPos(8, 56)
    descEntry:SetSize(450, 60)
    descEntry:SetMultiline(true)
    descEntry:SetPlaceholderText("Beschreibung")
    DDRPT.UI.StyleEntry(descEntry)

    DDRPT.UI.CreateLabel(createPanel, "Reports (CSV)", 470, 40)
    local reportLinks = vgui.Create("DTextEntry", createPanel)
    reportLinks:SetPos(470, 56)
    reportLinks:SetSize(180, 22)
    reportLinks:SetPlaceholderText("Reports IDs, CSV")
    DDRPT.UI.StyleEntry(reportLinks)

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(470, 84)
    createBtn:SetSize(180, 26)
    createBtn:SetText("Akte anlegen")
    DDRPT.UI.StyleButton(createBtn)
    createBtn.DoClick = function()
        local links = {}
        for _, id in ipairs(string.Explode(",", reportLinks:GetValue())) do
            local trimmed = string.Trim(id)
            if trimmed ~= "" then
                table.insert(links, tonumber(trimmed))
            end
        end
        net.Start(NET.CaseCreateRequest)
        net.WriteTable({
            title = titleEntry:GetValue(),
            status = statusEntry:GetValue(),
            description = descEntry:GetValue(),
            report_links = links,
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
