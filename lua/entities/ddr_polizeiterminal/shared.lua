ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "DDR Polizei-Terminal"
ENT.Author = "DDRPT"
ENT.Category = "DDR RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
end
