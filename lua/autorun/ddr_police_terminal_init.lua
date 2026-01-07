DDRPT = DDRPT or {}

AddCSLuaFile("ddr_police_terminal/sh_config.lua")
AddCSLuaFile("ddr_police_terminal/sh_net.lua")

include("ddr_police_terminal/sh_config.lua")
include("ddr_police_terminal/sh_net.lua")

if SERVER then
    AddCSLuaFile("ddr_police_terminal/client/cl_ui.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_reports.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_cases.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_people.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_bolo.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_evidence.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_duty.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_border.lua")
    AddCSLuaFile("ddr_police_terminal/client/cl_customs.lua")

    include("ddr_police_terminal/server/sv_mysql.lua")
    include("ddr_police_terminal/server/sv_core.lua")
    include("ddr_police_terminal/server/sv_reports.lua")
    include("ddr_police_terminal/server/sv_cases.lua")
    include("ddr_police_terminal/server/sv_people.lua")
    include("ddr_police_terminal/server/sv_bolo.lua")
    include("ddr_police_terminal/server/sv_evidence.lua")
    include("ddr_police_terminal/server/sv_duty.lua")
    include("ddr_police_terminal/server/sv_border.lua")
    include("ddr_police_terminal/server/sv_customs.lua")
else
    include("ddr_police_terminal/client/cl_ui.lua")
    include("ddr_police_terminal/client/cl_reports.lua")
    include("ddr_police_terminal/client/cl_cases.lua")
    include("ddr_police_terminal/client/cl_people.lua")
    include("ddr_police_terminal/client/cl_bolo.lua")
    include("ddr_police_terminal/client/cl_evidence.lua")
    include("ddr_police_terminal/client/cl_duty.lua")
    include("ddr_police_terminal/client/cl_border.lua")
    include("ddr_police_terminal/client/cl_customs.lua")
end
