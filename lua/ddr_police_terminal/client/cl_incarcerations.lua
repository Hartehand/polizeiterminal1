DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildIncarcerationsTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)
    DDRPT.UI.ApplyPanelStyle(panel)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Datum")
    list:AddColumn("Person")
    list:AddColumn("Dauer")
    list:AddColumn("Grund")
    list:AddColumn("Akte")
    list:AddColumn("Anzeige")
    list:AddColumn("Beamte")
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
        net.Start(NET.IncarcerationListRequest)
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
        if page * DDRPT.Config.Pagination.Incarcerations < total then
            page = page + 1
            requestList()
        end
    end

    net.Receive(NET.IncarcerationListResponse, function()
        page = net.ReadUInt(16)
        net.ReadUInt(16)
        total = net.ReadUInt(32)
        local rows = net.ReadTable() or {}
        list:Clear()
        for _, row in ipairs(rows) do
            DDRPT.UI.AddListLine(
                list,
                row.created_at or "",
                row.subject_name or "",
                tostring(row.duration_minutes or ""),
                row.reason or "",
                row.case_id or "",
                row.report_id or "",
                row.officers or ""
            )
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(120)
    createPanel:DockMargin(0, 8, 0, 0)
    DDRPT.UI.ApplyPanelStyle(createPanel)

    local subjectEntry = vgui.Create("DTextEntry", createPanel)
    subjectEntry:SetPos(8, 8)
    subjectEntry:SetSize(160, 22)
    subjectEntry:SetPlaceholderText("Person")
    DDRPT.UI.StyleEntry(subjectEntry)

    local durationEntry = vgui.Create("DTextEntry", createPanel)
    durationEntry:SetPos(180, 8)
    durationEntry:SetSize(80, 22)
    durationEntry:SetPlaceholderText("Dauer (Min)")
    DDRPT.UI.StyleEntry(durationEntry)

    local caseEntry = vgui.Create("DTextEntry", createPanel)
    caseEntry:SetPos(270, 8)
    caseEntry:SetSize(70, 22)
    caseEntry:SetPlaceholderText("Akte-ID")
    DDRPT.UI.StyleEntry(caseEntry)

    local reportEntry = vgui.Create("DTextEntry", createPanel)
    reportEntry:SetPos(350, 8)
    reportEntry:SetSize(70, 22)
    reportEntry:SetPlaceholderText("Anzeige-ID")
    DDRPT.UI.StyleEntry(reportEntry)

    local officersEntry = vgui.Create("DTextEntry", createPanel)
    officersEntry:SetPos(430, 8)
    officersEntry:SetSize(180, 22)
    officersEntry:SetPlaceholderText("Beamte (CSV)")
    DDRPT.UI.StyleEntry(officersEntry)

    local reasonEntry = vgui.Create("DTextEntry", createPanel)
    reasonEntry:SetPos(8, 36)
    reasonEntry:SetSize(420, 60)
    reasonEntry:SetMultiline(true)
    reasonEntry:SetPlaceholderText("Grund")
    DDRPT.UI.StyleEntry(reasonEntry)

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(440, 36)
    createBtn:SetSize(170, 26)
    createBtn:SetText("Inhaftierung speichern")
    DDRPT.UI.StyleButton(createBtn)
    createBtn.DoClick = function()
        local officers = {}
        for _, name in ipairs(string.Explode(",", officersEntry:GetValue())) do
            local trimmed = string.Trim(name)
            if trimmed ~= "" then
                table.insert(officers, trimmed)
            end
        end
        net.Start(NET.IncarcerationCreateRequest)
        net.WriteTable({
            subject_name = subjectEntry:GetValue(),
            reason = reasonEntry:GetValue(),
            duration_minutes = tonumber(durationEntry:GetValue()) or 0,
            case_id = tonumber(caseEntry:GetValue()) or nil,
            report_id = tonumber(reportEntry:GetValue()) or nil,
            officers = officers,
        })
        net.SendToServer()
    end

    requestList()
    return panel
end
