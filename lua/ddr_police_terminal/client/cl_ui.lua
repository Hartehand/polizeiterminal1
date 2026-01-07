DDRPT = DDRPT or {}
local NET = DDRPT.Net

DDRPT.UI = DDRPT.UI or {}
DDRPT.UI.Colors = {
    Background = Color(18, 18, 18, 240),
    Panel = Color(28, 28, 28, 255),
    Accent = Color(50, 50, 50, 255),
    Text = Color(235, 235, 235),
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

net.Receive(NET.OpenTerminal, function()
    DDRPT.UI:OpenTerminal()
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
end

function DDRPT.UI.StyleEntry(entry)
    if not IsValid(entry) then return end
    entry:SetTextColor(DDRPT.UI.Colors.Text)
    if entry.SetCursorColor then
        entry:SetCursorColor(DDRPT.UI.Colors.Text)
    end
    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, DDRPT.UI.Colors.Accent)
        if self.DrawTextEntryText then
            self:DrawTextEntryText(DDRPT.UI.Colors.Text, DDRPT.UI.Colors.Text, DDRPT.UI.Colors.Text)
        end
    end
end

function DDRPT.UI.StyleButton(button)
    if not IsValid(button) then return end
    button:SetTextColor(DDRPT.UI.Colors.Text)
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
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
            if self.SetTextColor then
                self:SetTextColor(DDRPT.UI.Colors.Text)
            end
        end
    end
    return line
end
