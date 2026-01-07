DDRPT = DDRPT or {}
local NET = DDRPT.Net
local DB = DDRPT.DB

local function log(msg)
    MsgC(Color(120, 200, 255), DDRPT.Config.AddonPrefix .. " ", color_white, msg .. "\n")
end

for _, name in pairs(NET) do
    util.AddNetworkString(name)
end

DDRPT.RateLimits = DDRPT.RateLimits or {}

function DDRPT:Notify(ply, msg)
    if not IsValid(ply) then return end
    net.Start(NET.Notify)
    net.WriteString(msg)
    net.Send(ply)
end

function DDRPT:HasAccess(ply)
    if not IsValid(ply) then return false end
    if DDRPT.Config and DDRPT.Config.RefreshTeams then
        if DDRPT.Config.AccessTeams and table.Count(DDRPT.Config.AccessTeams) == 0 then
            DDRPT.Config.RefreshTeams()
        end
    end
    return DDRPT.Config.AccessTeams[ply:Team()] == true
end

function DDRPT:GetRoleGroup(ply)
    if not IsValid(ply) then return nil end
    for _, group in pairs(DDRPT.Config.RoleGroups) do
        if group.Teams[ply:Team()] then
            return group
        end
    end
    return nil
end

function DDRPT:HasPermission(ply, perm)
    local group = self:GetRoleGroup(ply)
    if not group then return false end
    return group.Permissions[perm] == true
end

function DDRPT:CheckRate(ply, key)
    local limit = DDRPT.Config.NetRateLimits[key] or 0.5
    DDRPT.RateLimits[ply] = DDRPT.RateLimits[ply] or {}
    local last = DDRPT.RateLimits[ply][key] or 0
    if CurTime() - last < limit then
        return false
    end
    DDRPT.RateLimits[ply][key] = CurTime()
    return true
end

hook.Add("PlayerDisconnected", "DDRPT_RateLimitCleanup", function(ply)
    DDRPT.RateLimits[ply] = nil
end)

function DDRPT:SendOpenTerminal(ply)
    net.Start(NET.OpenTerminal)
    net.Send(ply)
end

function DDRPT:EnsureTables()
    local queries = {
        [[CREATE TABLE IF NOT EXISTS ddr_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            report_no VARCHAR(32) DEFAULT NULL,
            reporter VARCHAR(128) NOT NULL,
            accused_name VARCHAR(128) NOT NULL,
            accused_steamid64 VARCHAR(32) DEFAULT NULL,
            category VARCHAR(64) NOT NULL,
            location VARCHAR(128) NOT NULL,
            occurred_at DATETIME NOT NULL,
            description TEXT NOT NULL,
            witnesses TEXT,
            evidence TEXT,
            priority VARCHAR(16) NOT NULL,
            status VARCHAR(32) NOT NULL,
            created_by VARCHAR(32) NOT NULL,
            assignee VARCHAR(32) DEFAULT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            INDEX idx_report_no (report_no),
            INDEX idx_status (status),
            INDEX idx_category (category),
            INDEX idx_accused (accused_name)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_report_comments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            report_id INT NOT NULL,
            author VARCHAR(128) NOT NULL,
            author_steamid64 VARCHAR(32) NOT NULL,
            comment TEXT NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_report_id (report_id)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_report_audit (
            id INT AUTO_INCREMENT PRIMARY KEY,
            report_id INT NOT NULL,
            action VARCHAR(64) NOT NULL,
            actor VARCHAR(128) NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_audit_report (report_id)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_cases (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(128) NOT NULL,
            description TEXT,
            status VARCHAR(32) NOT NULL,
            assignees TEXT,
            linked_people TEXT,
            linked_evidence TEXT,
            created_by VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            INDEX idx_case_status (status)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_case_links (
            id INT AUTO_INCREMENT PRIMARY KEY,
            case_id INT NOT NULL,
            report_id INT NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_case_id (case_id),
            INDEX idx_report_link (report_id)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_person_notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steamid64 VARCHAR(32) NOT NULL,
            person_name VARCHAR(128) NOT NULL,
            note TEXT NOT NULL,
            is_secret TINYINT(1) NOT NULL DEFAULT 0,
            author VARCHAR(128) NOT NULL,
            author_steamid64 VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            team_snapshot VARCHAR(64),
            tags TEXT,
            INDEX idx_person (steamid64)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_bolos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            target_name VARCHAR(128) NOT NULL,
            target_steamid64 VARCHAR(32) DEFAULT NULL,
            reason TEXT NOT NULL,
            danger VARCHAR(32) NOT NULL,
            expires_at DATETIME,
            created_by VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            active TINYINT(1) NOT NULL DEFAULT 1,
            INDEX idx_bolo_active (active)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_evidence (
            id INT AUTO_INCREMENT PRIMARY KEY,
            evidence_type VARCHAR(32) NOT NULL,
            description TEXT NOT NULL,
            related_report INT DEFAULT NULL,
            related_case INT DEFAULT NULL,
            storage_location VARCHAR(128) NOT NULL,
            created_by VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_evidence_report (related_report),
            INDEX idx_evidence_case (related_case)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_evidence_custody (
            id INT AUTO_INCREMENT PRIMARY KEY,
            evidence_id INT NOT NULL,
            holder VARCHAR(128) NOT NULL,
            note TEXT NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_evidence_id (evidence_id)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_duty_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            officer VARCHAR(128) NOT NULL,
            officer_steamid64 VARCHAR(32) NOT NULL,
            entry_type VARCHAR(64) NOT NULL,
            content TEXT NOT NULL,
            created_at DATETIME NOT NULL,
            supervisor_note TEXT,
            INDEX idx_duty_officer (officer_steamid64)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_border_checks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            person_name VARCHAR(128) NOT NULL,
            person_steamid64 VARCHAR(32) DEFAULT NULL,
            document_checked TINYINT(1) NOT NULL DEFAULT 0,
            result VARCHAR(32) NOT NULL,
            reason TEXT,
            created_by VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_border_person (person_name)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_customs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            person_name VARCHAR(128) NOT NULL,
            origin VARCHAR(64) NOT NULL,
            declaration TEXT NOT NULL,
            duty_paid TINYINT(1) NOT NULL DEFAULT 0,
            created_by VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_customs_person (person_name)
        )]],
        [[CREATE TABLE IF NOT EXISTS ddr_incarcerations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            subject_name VARCHAR(128) NOT NULL,
            reason TEXT NOT NULL,
            duration_minutes INT NOT NULL,
            case_id INT DEFAULT NULL,
            report_id INT DEFAULT NULL,
            officers TEXT NOT NULL,
            created_by VARCHAR(32) NOT NULL,
            created_at DATETIME NOT NULL,
            INDEX idx_incarceration_case (case_id),
            INDEX idx_incarceration_report (report_id)
        )]],
    }

    for _, sql in ipairs(queries) do
        DB:Query(sql)
    end
end

hook.Add("DDRPT_DB_Connected", "DDRPT_CreateTables", function()
    DDRPT:EnsureTables()
end)

hook.Add("InitPostEntity", "DDRPT_RefreshTeams", function()
    if DDRPT.Config and DDRPT.Config.RefreshTeams then
        DDRPT.Config.RefreshTeams()
    end
end)

hook.Add("DarkRPFinishedLoading", "DDRPT_RefreshTeams_DarkRP", function()
    if DDRPT.Config and DDRPT.Config.RefreshTeams then
        DDRPT.Config.RefreshTeams()
    end
end)

hook.Add("PlayerInitialSpawn", "DDRPT_RefreshTeams_Player", function()
    if DDRPT.Config and DDRPT.Config.RefreshTeams then
        DDRPT.Config.RefreshTeams()
    end
end)

hook.Add("PlayerUse", "DDRPT_TerminalUse", function(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= "ddr_polizeiterminal" then return end
    if not DDRPT:HasAccess(ply) then
        ent.NextDenied = ent.NextDenied or {}
        ent.NextDenied[ply] = ent.NextDenied[ply] or 0
        if CurTime() < ent.NextDenied[ply] then return end
        ent.NextDenied[ply] = CurTime() + 2
        DDRPT:Notify(ply, "Kein Zugriff auf das Polizei-Terminal.")
        return false
    end
    DDRPT:SendOpenTerminal(ply)
    return false
end)

hook.Add("PlayerInitialSpawn", "DDRPT_BoloLoginNotice", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        if not DDRPT:HasAccess(ply) then return end
        if not DDRPT.Config.Notifications.BoloLoginNotice then return end
        if not DDRPT.ActiveBolos then return end
        local count = #DDRPT.ActiveBolos
        if count > 0 then
            DDRPT:Notify(ply, "Aktive Fahndungen: " .. count)
        end
    end)
end)
