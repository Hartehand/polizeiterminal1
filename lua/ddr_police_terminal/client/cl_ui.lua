DDRPT = DDRPT or {}
local NET = DDRPT.Net

DDRPT.UI = DDRPT.UI or {}
surface.CreateFont("DDRPT_Label", {
    font = "Roboto",
    size = 16,
    weight = 600,
})

DDRPT.UI.Colors = {
    Background = Color(55, 55, 55, 240),
    Panel = Color(70, 70, 70, 255),
    Accent = Color(95, 95, 95, 255),
    Text = Color(255, 255, 255),
    Placeholder = Color(210, 210, 210),
}

local function notify(msg)
    chat.AddText(Color(120, 200, 255), DDRPT.Config.AddonPrefix .. " ", color_white, msg)
end

net.Receive(NET.Notify, function()
    notify(net.ReadString())
end)

function DDRPT.UI:OpenTerminal()
    if IsValid(self.Frame) then
        self.Frame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(1000, 700)
    frame:Center()
    frame:SetTitle("DDR Polizei-Terminal")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, DDRPT.UI.Colors.Background)
        draw.RoundedBox(6, 4, 28, w - 8, h - 32, DDRPT.UI.Colors.Panel)
    end
    self.Frame = frame

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    sheet:AddSheet("Anzeigen", DDRPT.UI.BuildReportsTab())
    sheet:AddSheet("Akte/Fälle", DDRPT.UI.BuildCasesTab())
    sheet:AddSheet("Personenakte", DDRPT.UI.BuildPeopleTab())
    sheet:AddSheet("Fahndung", DDRPT.UI.BuildBoloTab())
    sheet:AddSheet("Beweise", DDRPT.UI.BuildEvidenceTab())
    sheet:AddSheet("Dienstbuch", DDRPT.UI.BuildDutyTab())
    sheet:AddSheet("Grenzkontrolle", DDRPT.UI.BuildBorderTab())
    sheet:AddSheet("Zoll", DDRPT.UI.BuildCustomsTab())
    sheet:AddSheet("Inhaftierungen", DDRPT.UI.BuildIncarcerationsTab())
end

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

function DDRPT.UI.ApplyPanelStyle(panel)
    if not IsValid(panel) then return end
    panel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, DDRPT.UI.Colors.Panel)
    end
end

function DDRPT.UI.StyleLabel(label)
    if not IsValid(label) then return end
    label:SetTextColor(DDRPT.UI.Colors.Text)
    label:SetFont("DDRPT_Label")
end

function DDRPT.UI.StyleEntry(entry)
    if not IsValid(entry) then return end
    entry:SetTextColor(DDRPT.UI.Colors.Text)
    if entry.SetCursorColor then
        entry:SetCursorColor(DDRPT.UI.Colors.Text)
    end
    if entry.SetPlaceholderText then
        local original = entry.SetPlaceholderText
        entry.SetPlaceholderText = function(self, text)
            self.DDRPT_Placeholder = text
            original(self, text)
        end
        if entry.GetPlaceholderText then
            entry.DDRPT_Placeholder = entry:GetPlaceholderText()
        end
    end
    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, DDRPT.UI.Colors.Accent)
        if self.DrawTextEntryText then
            local textColor = DDRPT.UI.Colors.Text
            if self.GetValue and self:GetValue() == "" then
                textColor = DDRPT.UI.Colors.Placeholder
            end
            self:DrawTextEntryText(textColor, DDRPT.UI.Colors.Text, DDRPT.UI.Colors.Text)
        else
            local value = ""
            if self.GetValue then
                value = self:GetValue() or ""
            elseif self.GetText then
                value = self:GetText() or ""
            end
            local color = DDRPT.UI.Colors.Text
            if value == "" then
                value = self.DDRPT_Placeholder or ""
                color = DDRPT.UI.Colors.Placeholder
            elseif self.DDRPT_Placeholder and value == self.DDRPT_Placeholder then
                color = DDRPT.UI.Colors.Placeholder
            end
            draw.SimpleText(value, "DDRPT_Label", 8, h * 0.5, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

function DDRPT.UI.StyleButton(button)
    if not IsValid(button) then return end
    button:SetTextColor(DDRPT.UI.Colors.Text)
    button:SetFont("DDRPT_Label")
    button.Paint = function(self, w, h)
        local color = self:IsHovered() and DDRPT.UI.Colors.Accent or DDRPT.UI.Colors.Panel
        draw.RoundedBox(4, 0, 0, w, h, color)
    end
end

function DDRPT.UI.StyleList(list)
    if not IsValid(list) then return end
    list:SetBackgroundColor(DDRPT.UI.Colors.Panel)
    list.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, DDRPT.UI.Colors.Panel)
    end
    for _, column in ipairs(list.Columns or {}) do
        if IsValid(column) then
            if column.SetTextColor then
                column:SetTextColor(DDRPT.UI.Colors.Text)
            end
            if column.SetFont then
                column:SetFont("DDRPT_Label")
            end
        end
    end
    local header = list:GetHeader()
    if IsValid(header) then
        header:SetTall(26)
        header.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, DDRPT.UI.Colors.Accent)
        end
    end
end

function DDRPT.UI.AddListLine(list, ...)
    if not IsValid(list) then return end
    local line = list:AddLine(...)
    if IsValid(line) then
        if line.SetTextColor then
            line:SetTextColor(DDRPT.UI.Colors.Text)
        end
        line.Paint = function(self, w, h)
            local isSelected = self:IsSelected()
            local bg = isSelected and Color(120, 120, 120, 160) or Color(0, 0, 0, 0)
            draw.RoundedBox(0, 0, 0, w, h, bg)
            if self.SetTextColor then
                self:SetTextColor(DDRPT.UI.Colors.Text)
            end
        end
    end
    return line
end

function DDRPT.UI.CreateLabel(parent, text, x, y)
    local label = vgui.Create("DLabel", parent)
    label:SetText(text)
    label:SetPos(x, y)
    label:SizeToContents()
    DDRPT.UI.StyleLabel(label)
    return label
end

function DDRPT.UI.SetComboPlaceholder(combo, text)
    if not IsValid(combo) then return end
    combo.DDRPT_Placeholder = text
    if combo.SetValue then
        combo:SetValue(text)
    end
end
