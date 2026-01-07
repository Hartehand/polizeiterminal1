DDRPT = DDRPT or {}
local NET = DDRPT.Net

local function buildLabel(parent, text)
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetText(text)
    lbl:SizeToContents()
    return lbl
end

function DDRPT.UI.BuildReportsTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)

    local filterPanel = vgui.Create("DPanel", panel)
    filterPanel:Dock(TOP)
    filterPanel:SetTall(60)
    filterPanel:DockMargin(0, 0, 0, 8)

    buildLabel(filterPanel, "Status"):SetPos(8, 8)
    local statusCombo = vgui.Create("DComboBox", filterPanel)
    statusCombo:SetPos(8, 26)
    statusCombo:SetSize(140, 22)
    statusCombo:AddChoice("")
    for _, status in ipairs(DDRPT.Config.ReportStatuses) do
        statusCombo:AddChoice(status)
    end

    buildLabel(filterPanel, "Kategorie"):SetPos(160, 8)
    local categoryCombo = vgui.Create("DComboBox", filterPanel)
    categoryCombo:SetPos(160, 26)
    categoryCombo:SetSize(160, 22)
    categoryCombo:AddChoice("")
    for _, cat in ipairs(DDRPT.Config.ReportCategories) do
        categoryCombo:AddChoice(cat)
    end

    buildLabel(filterPanel, "Beschuldigter"):SetPos(330, 8)
    local accusedEntry = vgui.Create("DTextEntry", filterPanel)
    accusedEntry:SetPos(330, 26)
    accusedEntry:SetSize(180, 22)

    buildLabel(filterPanel, "Vorgang"):SetPos(520, 8)
    local reportNoEntry = vgui.Create("DTextEntry", filterPanel)
    reportNoEntry:SetPos(520, 26)
    reportNoEntry:SetSize(160, 22)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("ID"):SetFixedWidth(40)
    list:AddColumn("Vorgang")
    list:AddColumn("Kategorie")
    list:AddColumn("Status")
    list:AddColumn("Beschuldigter")
    list:AddColumn("Priorität")
    list:AddColumn("Datum")

    local pagination = vgui.Create("DPanel", panel)
    pagination:Dock(BOTTOM)
    pagination:SetTall(40)
    pagination:DockMargin(0, 8, 0, 0)

    local page = 1
    local total = 0

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
        local filters = {
            status = statusCombo:GetValue() or "",
            category = categoryCombo:GetValue() or "",
            accused = accusedEntry:GetValue() or "",
            report_no = reportNoEntry:GetValue() or "",
        }
        net.Start(NET.ReportListRequest)
        net.WriteUInt(page, 16)
        net.WriteTable(filters)
        net.SendToServer()
    end

    prevBtn.DoClick = function()
        if page > 1 then
            page = page - 1
            requestList()
        end
    end

    nextBtn.DoClick = function()
        if page * DDRPT.Config.Pagination.Reports < total then
            page = page + 1
            requestList()
        end
    end

    local refreshBtn = vgui.Create("DButton", filterPanel)
    refreshBtn:SetPos(690, 24)
    refreshBtn:SetSize(80, 24)
    refreshBtn:SetText("Suchen")
    refreshBtn.DoClick = function()
        page = 1
        requestList()
    end

    list.OnRowSelected = function(_, rowIndex, row)
        local reportId = tonumber(row:GetColumnText(1))
        if not reportId then return end
        net.Start(NET.ReportDetailRequest)
        net.WriteUInt(reportId, 32)
        net.SendToServer()
    end

    net.Receive(NET.ReportListResponse, function()
        page = net.ReadUInt(16)
        local limit = net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            list:AddLine(row.id, row.report_no or "", row.category or "", row.status or "", row.accused_name or "", row.priority or "", row.created_at or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    net.Receive(NET.ReportDetailResponse, function()
        local report = net.ReadTable() or {}
        local comments = net.ReadTable() or {}
        local audits = net.ReadTable() or {}

        local detail = vgui.Create("DFrame")
        detail:SetSize(700, 600)
        detail:Center()
        detail:SetTitle("Anzeige " .. (report.report_no or ""))
        detail:MakePopup()

        local scroll = vgui.Create("DScrollPanel", detail)
        scroll:Dock(FILL)

        local info = vgui.Create("DPanel", scroll)
        info:Dock(TOP)
        info:SetTall(200)
        info:DockMargin(0, 0, 0, 8)

        local infoText = vgui.Create("DLabel", info)
        infoText:SetPos(8, 8)
        infoText:SetSize(680, 180)
        infoText:SetText(string.format(
            "Anzeigender: %s\nBeschuldigter: %s\nKategorie: %s\nTatort: %s\nZeitpunkt: %s\nPriorität: %s\nStatus: %s\nBeschreibung: %s\nZeugen: %s\nBeweismittel: %s",
            report.reporter or "",
            report.accused_name or "",
            report.category or "",
            report.location or "",
            report.occurred_at or "",
            report.priority or "",
            report.status or "",
            report.description or "",
            report.witnesses or "",
            report.evidence or ""
        ))

        local updatePanel = vgui.Create("DPanel", scroll)
        updatePanel:Dock(TOP)
        updatePanel:SetTall(60)
        updatePanel:DockMargin(0, 0, 0, 8)

        local statusBox = vgui.Create("DComboBox", updatePanel)
        statusBox:SetPos(8, 20)
        statusBox:SetSize(140, 22)
        for _, status in ipairs(DDRPT.Config.ReportStatuses) do
            statusBox:AddChoice(status)
        end
        statusBox:SetValue(report.status or DDRPT.Config.ReportStatuses[1])

        local assigneeEntry = vgui.Create("DTextEntry", updatePanel)
        assigneeEntry:SetPos(160, 20)
        assigneeEntry:SetSize(160, 22)
        assigneeEntry:SetText(report.assignee or "")

        local updateBtn = vgui.Create("DButton", updatePanel)
        updateBtn:SetPos(330, 18)
        updateBtn:SetSize(80, 26)
        updateBtn:SetText("Aktualisieren")
        updateBtn.DoClick = function()
            net.Start(NET.ReportUpdateRequest)
            net.WriteUInt(report.id or 0, 32)
            net.WriteTable({
                status = statusBox:GetValue(),
                assignee = assigneeEntry:GetValue(),
            })
            net.SendToServer()
        end

        local printBtn = vgui.Create("DButton", updatePanel)
        printBtn:SetPos(420, 18)
        printBtn:SetSize(80, 26)
        printBtn:SetText("Drucken")
        printBtn.DoClick = function()
            local printFrame = vgui.Create("DFrame")
            printFrame:SetSize(600, 500)
            printFrame:Center()
            printFrame:SetTitle("Druckansicht")
            printFrame:MakePopup()
            local label = vgui.Create("DLabel", printFrame)
            label:SetPos(12, 36)
            label:SetSize(580, 450)
            label:SetText(string.format("%s\n%s\nVorgang: %s\n\n%s",
                DDRPT.Config.DepartmentName,
                DDRPT.Config.PrintHeader,
                report.report_no or "",
                report.description or ""
            ))
        end

        local commentPanel = vgui.Create("DPanel", scroll)
        commentPanel:Dock(TOP)
        commentPanel:SetTall(90)
        commentPanel:DockMargin(0, 0, 0, 8)

        local commentEntry = vgui.Create("DTextEntry", commentPanel)
        commentEntry:SetPos(8, 8)
        commentEntry:SetSize(500, 24)
        local commentBtn = vgui.Create("DButton", commentPanel)
        commentBtn:SetPos(520, 8)
        commentBtn:SetSize(120, 24)
        commentBtn:SetText("Kommentar")
        commentBtn.DoClick = function()
            if commentEntry:GetValue() == "" then return end
            net.Start(NET.ReportCommentRequest)
            net.WriteUInt(report.id or 0, 32)
            net.WriteString(commentEntry:GetValue())
            net.SendToServer()
            commentEntry:SetText("")
        end

        local commentsList = vgui.Create("DListView", scroll)
        commentsList:Dock(TOP)
        commentsList:SetTall(140)
        commentsList:AddColumn("Datum")
        commentsList:AddColumn("Autor")
        commentsList:AddColumn("Kommentar")
        for _, comment in ipairs(comments) do
            commentsList:AddLine(comment.created_at or "", comment.author or "", comment.comment or "")
        end

        local auditList = vgui.Create("DListView", scroll)
        auditList:Dock(TOP)
        auditList:SetTall(140)
        auditList:AddColumn("Datum")
        auditList:AddColumn("Aktion")
        auditList:AddColumn("Bearbeiter")
        for _, audit in ipairs(audits) do
            auditList:AddLine(audit.created_at or "", audit.action or "", audit.actor or "")
        end
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(200)
    createPanel:DockMargin(0, 8, 0, 0)

    local reporterEntry = vgui.Create("DTextEntry", createPanel)
    reporterEntry:SetPos(8, 8)
    reporterEntry:SetSize(140, 22)
    reporterEntry:SetPlaceholderText("Anzeigender")

    local accusedEntry2 = vgui.Create("DTextEntry", createPanel)
    accusedEntry2:SetPos(160, 8)
    accusedEntry2:SetSize(140, 22)
    accusedEntry2:SetPlaceholderText("Beschuldigter")

    local categoryCreate = vgui.Create("DComboBox", createPanel)
    categoryCreate:SetPos(310, 8)
    categoryCreate:SetSize(140, 22)
    for _, cat in ipairs(DDRPT.Config.ReportCategories) do
        categoryCreate:AddChoice(cat)
    end
    categoryCreate:SetValue(DDRPT.Config.ReportCategories[1])

    local locationEntry = vgui.Create("DTextEntry", createPanel)
    locationEntry:SetPos(460, 8)
    locationEntry:SetSize(140, 22)
    locationEntry:SetPlaceholderText("Tatort")

    local descriptionEntry = vgui.Create("DTextEntry", createPanel)
    descriptionEntry:SetPos(8, 40)
    descriptionEntry:SetSize(592, 60)
    descriptionEntry:SetMultiline(true)
    descriptionEntry:SetPlaceholderText("Beschreibung")

    local witnessesEntry = vgui.Create("DTextEntry", createPanel)
    witnessesEntry:SetPos(8, 110)
    witnessesEntry:SetSize(200, 22)
    witnessesEntry:SetPlaceholderText("Zeugen")

    local evidenceEntry = vgui.Create("DTextEntry", createPanel)
    evidenceEntry:SetPos(220, 110)
    evidenceEntry:SetSize(200, 22)
    evidenceEntry:SetPlaceholderText("Beweismittel")

    local priorityCombo = vgui.Create("DComboBox", createPanel)
    priorityCombo:SetPos(430, 110)
    priorityCombo:SetSize(120, 22)
    for _, prio in ipairs(DDRPT.Config.PriorityLevels) do
        priorityCombo:AddChoice(prio)
    end
    priorityCombo:SetValue(DDRPT.Config.PriorityLevels[1])

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(560, 110)
    createBtn:SetSize(120, 26)
    createBtn:SetText("Anzeige anlegen")
    createBtn.DoClick = function()
        net.Start(NET.ReportCreateRequest)
        net.WriteTable({
            reporter = reporterEntry:GetValue(),
            accused_name = accusedEntry2:GetValue(),
            category = categoryCreate:GetValue(),
            location = locationEntry:GetValue(),
            description = descriptionEntry:GetValue(),
            witnesses = witnessesEntry:GetValue(),
            evidence = evidenceEntry:GetValue(),
            priority = priorityCombo:GetValue(),
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
