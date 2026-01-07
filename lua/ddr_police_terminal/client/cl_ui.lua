DDRPT = DDRPT or {}
local NET = DDRPT.Net

DDRPT.UI = DDRPT.UI or {}

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
end

net.Receive(NET.OpenTerminal, function()
    DDRPT.UI:OpenTerminal()
end)
