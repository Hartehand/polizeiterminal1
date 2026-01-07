DDRPT = DDRPT or {}
local NET = DDRPT.Net

DDRPT.UI = DDRPT.UI or {}

-- =========================
-- Fonts
-- =========================
surface.CreateFont("DDRPT_Label", {
    font = "Roboto",
    size = 16,
    weight = 600,
})

surface.CreateFont("DDRPT_Tab", {
    font = "Roboto",
    size = 15,
    weight = 700,
})

-- =========================
-- Colors
-- =========================
DDRPT.UI.Colors = {
    Background   = Color(55, 55, 55, 240),
    Panel        = Color(70, 70, 70, 255),
    Accent       = Color(95, 95, 95, 255),
    AccentDark   = Color(55, 55, 55, 255),
    Text         = Color(255, 255, 255, 255),
    Placeholder  = Color(200, 200, 200, 255),
    Selected     = Color(90, 100, 130, 200),
    Line         = Color(35, 35, 35, 255),
}

-- =========================
-- Notify
-- =========================
local function notify(msg)
    chat.AddText(Color(120, 200, 255), (DDRPT.Config.AddonPrefix or "[DDRPT]") .. " ", color_white, msg)
end

net.Receive(NET.Notify, function()
    notify(net.ReadString())
end)

-- =========================
-- Styling helpers
-- =========================
function DDRPT.UI.ApplyPanelStyle(panel)
    if not IsValid(panel) then return end
    panel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, DDRPT.UI.Colors.Panel)
    end
end

-- IMPORTANT: Many files call :SizeToContents() BEFORE StyleLabel() sets the font.
-- That causes ellipsis like "St..." / "Kate..." because width was calculated with default font.
-- So we re-SizeToContents() after setting font.
function DDRPT.UI.StyleLabel(label)
    if not IsValid(label) then return end
    if label.SetFont then label:SetFont("DDRPT_Label") end
    if label.SetTextColor then label:SetTextColor(DDRPT.UI.Colors.Text) end
    if label.SizeToContents then label:SizeToContents() end
end

function DDRPT.UI.StyleButton(button)
    if not IsValid(button) then return end
    button:SetTextColor(DDRPT.UI.Colors.Text)
    button:SetFont("DDRPT_Label")

    button.Paint = function(self, w, h)
        local col = self:IsHovered() and DDRPT.UI.Colors.Accent or DDRPT.UI.Colors.Panel
        draw.RoundedBox(4, 0, 0, w, h, col)
        surface.SetDrawColor(DDRPT.UI.Colors.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
end

function DDRPT.UI.StyleEntry(entry)
    if not IsValid(entry) then return end

    if entry.SetTextColor then entry:SetTextColor(DDRPT.UI.Colors.Text) end
    if entry.SetCursorColor then entry:SetCursorColor(DDRPT.UI.Colors.Text) end
    if entry.SetFont then entry:SetFont("DDRPT_Label") end

    local isCombo = entry.GetName and entry:GetName() == "DComboBox"
    local isTextEntry = entry.GetName and entry:GetName() == "DTextEntry"

    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, DDRPT.UI.Colors.AccentDark)
        surface.SetDrawColor(DDRPT.UI.Colors.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- TextEntry
        if isTextEntry and self.DrawTextEntryText then
            local placeholder = self.GetPlaceholderText and (self:GetPlaceholderText() or "") or ""
            local value = self.GetValue and (self:GetValue() or "") or ""

            if value == "" and placeholder ~= "" then
                draw.SimpleText(
                    placeholder,
                    "DDRPT_Label",
                    8, h * 0.5,
                    DDRPT.UI.Colors.Placeholder,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
            end

            self:DrawTextEntryText(DDRPT.UI.Colors.Text, DDRPT.UI.Colors.Text, DDRPT.UI.Colors.Text)
            return
        end

        -- ComboBox (placeholder behavior)
        if isCombo then
            local txt = self.GetValue and (self:GetValue() or "") or ""
            local col = DDRPT.UI.Colors.Text
            if self.DDRPT_Placeholder and txt == self.DDRPT_Placeholder then
                col = DDRPT.UI.Colors.Placeholder
            end

            draw.SimpleText(txt, "DDRPT_Label", 8, h * 0.5, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- dropdown arrow
            surface.SetDrawColor(DDRPT.UI.Colors.Text)
            local cx, cy = w - 14, h * 0.5
            surface.DrawLine(cx - 4, cy - 1, cx, cy + 3)
            surface.DrawLine(cx, cy + 3, cx + 4, cy - 1)
            return
        end
    end
end

function DDRPT.UI.CreateLabel(parent, text, x, y)
    local label = vgui.Create("DLabel", parent)
    label:SetText(text)
    label:SetPos(x, y)
    DDRPT.UI.StyleLabel(label) -- StyleLabel does SizeToContents after setting font
    return label
end

function DDRPT.UI.SetComboPlaceholder(combo, text)
    if not IsValid(combo) then return end
    combo.DDRPT_Placeholder = text
    if combo.SetValue then combo:SetValue(text) end
end

-- =========================
-- List styling (fixes black-on-dark + header)
-- =========================
local function FindListHeader(list)
    if not IsValid(list) then return nil end
    if IsValid(list.Header) then return list.Header end
    for _, ch in ipairs(list:GetChildren()) do
        if IsValid(ch) and ch:GetName() == "DListView_Header" then
            return ch
        end
    end
    return nil
end

function DDRPT.UI.StyleList(list)
    if not IsValid(list) then return end

    list:SetDataHeight(24)
    list:SetHeaderHeight(26)

    list.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, DDRPT.UI.Colors.Panel)
        surface.SetDrawColor(DDRPT.UI.Colors.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Style header + its buttons
    local header = FindListHeader(list)
    if IsValid(header) then
        header:SetTall(26)
        header.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, DDRPT.UI.Colors.Accent)
            surface.SetDrawColor(DDRPT.UI.Colors.Line)
            surface.DrawLine(0, h - 1, w, h - 1)
        end

        for _, btn in ipairs(header:GetChildren()) do
            if IsValid(btn) then
                if btn.SetFont then btn:SetFont("DDRPT_Label") end
                if btn.SetTextColor then btn:SetTextColor(DDRPT.UI.Colors.Text) end
            end
        end
    end

    -- Make sure columns use our font (some versions store buttons in list.Columns)
    for _, column in ipairs(list.Columns or {}) do
        if IsValid(column) then
            if column.SetFont then column:SetFont("DDRPT_Label") end
            if column.SetTextColor then column:SetTextColor(DDRPT.UI.Colors.Text) end
        end
    end

    -- Patch AddLine ONCE per list so each row column label gets correct text color
    if not list.DDRPT_AddLinePatched then
        list.DDRPT_AddLinePatched = true
        local oldAddLine = list.AddLine

        function list:AddLine(...)
            local line = oldAddLine(self, ...)

            if IsValid(line) then
                line.Paint = function(selfLine, w, h)
                    if selfLine:IsSelected() then
                        surface.SetDrawColor(DDRPT.UI.Colors.Selected)
                        surface.DrawRect(0, 0, w, h)
                    end
                    surface.SetDrawColor(DDRPT.UI.Colors.Line)
                    surface.DrawLine(0, h - 1, w, h - 1)
                end

                -- THIS fixes "black text on dark background"
                for _, col in ipairs(line.Columns or {}) do
                    if IsValid(col) then
                        if col.SetTextColor then col:SetTextColor(DDRPT.UI.Colors.Text) end
                        if col.SetFont then col:SetFont("DDRPT_Label") end
                        if col.SizeToContents then col:SizeToContents() end
                    end
                end
            end

            return line
        end
    end
end

function DDRPT.UI.AddListLine(list, ...)
    if not IsValid(list) then return end
    return list:AddLine(...)
end

-- =========================
-- PropertySheet tab styling (prevents clipping/ellipsis)
-- =========================
local function StylePropertySheet(sheet)
    if not IsValid(sheet) then return end

    timer.Simple(0, function()
        if not IsValid(sheet) then return end

        for _, ch in ipairs(sheet:GetChildren()) do
            if IsValid(ch) and ch:GetName() == "DTabBar" then
                ch:SetTall(30)

                ch.Paint = function(self, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, DDRPT.UI.Colors.Panel)
                    surface.SetDrawColor(DDRPT.UI.Colors.Line)
                    surface.DrawLine(0, h - 1, w, h - 1)
                end

                for _, btn in ipairs(ch:GetChildren()) do
                    if IsValid(btn) and btn.SetFont then
                        btn:SetFont("DDRPT_Tab")
                        btn:SetTextColor(DDRPT.UI.Colors.Text)
                        btn:SetTall(28)

                        btn.Paint = function(selfBtn, w, h)
                            local active = selfBtn:GetPropertySheet() and selfBtn:GetPropertySheet():GetActiveTab() == selfBtn
                            local col = active and DDRPT.UI.Colors.Accent or DDRPT.UI.Colors.Panel
                            draw.RoundedBox(4, 2, 2, w - 4, h - 4, col)
                            surface.SetDrawColor(DDRPT.UI.Colors.Line)
                            surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
                        end

                        -- re-calc size after font applied to avoid ellipsis on tab text too
                        if btn.SizeToContentsX then btn:SizeToContentsX(10) end
                    end
                end
            end
        end
    end)
end

-- =========================
-- Open Terminal
-- =========================
function DDRPT.UI:OpenTerminal()
    if IsValid(self.Frame) then
        self.Frame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(1000, 700)
    frame:Center()
    frame:SetTitle("DDR Polizei-Terminal")
    frame:MakePopup()
    frame.Paint = function(selfF, w, h)
        draw.RoundedBox(8, 0, 0, w, h, DDRPT.UI.Colors.Background)
        draw.RoundedBox(6, 4, 28, w - 8, h - 32, DDRPT.UI.Colors.Panel)
        surface.SetDrawColor(DDRPT.UI.Colors.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    self.Frame = frame

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    sheet:AddSheet("Anzeigen",        DDRPT.UI.BuildReportsTab())
    sheet:AddSheet("Akte/Fälle",      DDRPT.UI.BuildCasesTab())
    sheet:AddSheet("Personenakte",    DDRPT.UI.BuildPeopleTab())
    sheet:AddSheet("Fahndung",        DDRPT.UI.BuildBoloTab())
    sheet:AddSheet("Beweise",         DDRPT.UI.BuildEvidenceTab())
    sheet:AddSheet("Dienstbuch",      DDRPT.UI.BuildDutyTab())
    sheet:AddSheet("Grenzkontrolle",  DDRPT.UI.BuildBorderTab())
    sheet:AddSheet("Zoll",            DDRPT.UI.BuildCustomsTab())
    sheet:AddSheet("Inhaftierungen",  DDRPT.UI.BuildIncarcerationsTab())

    StylePropertySheet(sheet)
end

-- =========================
-- Net open flow
-- =========================
net.Receive(NET.OpenTerminalPrompt, function()
    net.Start(NET.OpenTerminalRequest)
    net.SendToServer()
end)

net.Receive(NET.OpenTerminalResult, function()
    local allowed = net.ReadBool()
    local reason = net.ReadString()
    if allowed then
        DDRPT.UI:OpenTerminal()
    else
        notify(reason ~= "" and reason or "Kein Zugriff auf das Terminal.")
    end
end)
function DDRPT.UI.GetComboValue(combo)
    if not IsValid(combo) then return "" end
    local v = combo.GetValue and (combo:GetValue() or "") or ""
    if combo.DDRPT_Placeholder and v == combo.DDRPT_Placeholder then
        return ""
    end
    return v
end
