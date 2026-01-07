DDRPT = DDRPT or {}
local NET = DDRPT.Net

function DDRPT.UI.BuildCasesTab()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(8, 8, 8, 8)

    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("ID"):SetFixedWidth(40)
    list:AddColumn("Titel")
    list:AddColumn("Status")
    list:AddColumn("Aktualisiert")

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
            list:AddLine(row.id, row.title or "", row.status or "", row.updated_at or "")
        end
        pageLabel:SetText(string.format("Seite %d (%d Einträge)", page, total))
        pageLabel:SizeToContents()
    end)

    net.Receive(NET.CaseDetailResponse, function()
        local caseData = net.ReadTable() or {}
        local links = net.ReadTable() or {}
        local frame = vgui.Create("DFrame")
        frame:SetSize(600, 400)
        frame:Center()
        frame:SetTitle("Akte " .. (caseData.title or ""))
        frame:MakePopup()
        local label = vgui.Create("DLabel", frame)
        label:SetPos(12, 40)
        label:SetSize(560, 320)
        label:SetText(string.format("Status: %s\nBeschreibung: %s\nAssignees: %s\nReports: %s",
            caseData.status or "",
            caseData.description or "",
            caseData.assignees or "",
            util.TableToJSON(links or {})
        ))
    end)

    local createPanel = vgui.Create("DPanel", panel)
    createPanel:Dock(BOTTOM)
    createPanel:SetTall(120)
    createPanel:DockMargin(0, 8, 0, 0)

    local titleEntry = vgui.Create("DTextEntry", createPanel)
    titleEntry:SetPos(8, 8)
    titleEntry:SetSize(200, 22)
    titleEntry:SetPlaceholderText("Titel")

    local statusEntry = vgui.Create("DTextEntry", createPanel)
    statusEntry:SetPos(220, 8)
    statusEntry:SetSize(120, 22)
    statusEntry:SetPlaceholderText("Status")
    statusEntry:SetText("Neu")

    local descEntry = vgui.Create("DTextEntry", createPanel)
    descEntry:SetPos(8, 36)
    descEntry:SetSize(450, 60)
    descEntry:SetMultiline(true)
    descEntry:SetPlaceholderText("Beschreibung")

    local reportLinks = vgui.Create("DTextEntry", createPanel)
    reportLinks:SetPos(470, 36)
    reportLinks:SetSize(180, 22)
    reportLinks:SetPlaceholderText("Reports IDs, CSV")

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetPos(470, 64)
    createBtn:SetSize(180, 26)
    createBtn:SetText("Akte anlegen")
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
