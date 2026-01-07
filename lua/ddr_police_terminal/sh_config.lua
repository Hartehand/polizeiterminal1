DDRPT = DDRPT or {}
DDRPT.Config = DDRPT.Config or {}

DDRPT.Config.AddonPrefix = "[DDR Polizei-Terminal]"
DDRPT.Config.DepartmentName = "Volkspolizei Dienststelle Mitte"
DDRPT.Config.PrintHeader = "Volkspolizei - Anzeige"

local function addTeam(list, teamId)
    if teamId ~= nil then
        list[teamId] = true
    end
end

function DDRPT.Config.RefreshTeams()
    DDRPT.Config.AccessTeams = DDRPT.Config.AccessTeams or {}
    DDRPT.Config.BorderAccessTeams = DDRPT.Config.BorderAccessTeams or {}
    DDRPT.Config.RoleGroups.VP.Teams = DDRPT.Config.RoleGroups.VP.Teams or {}
    DDRPT.Config.RoleGroups.VP_LEITUNG.Teams = DDRPT.Config.RoleGroups.VP_LEITUNG.Teams or {}
    DDRPT.Config.RoleGroups.MFS.Teams = DDRPT.Config.RoleGroups.MFS.Teams or {}

    addTeam(DDRPT.Config.AccessTeams, TEAM_POLICE)
    addTeam(DDRPT.Config.AccessTeams, TEAM_CHIEF)

    addTeam(DDRPT.Config.BorderAccessTeams, TEAM_POLICE)
    addTeam(DDRPT.Config.BorderAccessTeams, TEAM_BORDER)

    addTeam(DDRPT.Config.RoleGroups.VP.Teams, TEAM_POLICE)
    addTeam(DDRPT.Config.RoleGroups.VP_LEITUNG.Teams, TEAM_CHIEF)
    addTeam(DDRPT.Config.RoleGroups.MFS.Teams, TEAM_MFS)
end

DDRPT.Config.AccessTeams = {}
addTeam(DDRPT.Config.AccessTeams, TEAM_POLICE)
addTeam(DDRPT.Config.AccessTeams, TEAM_CHIEF)

DDRPT.Config.RoleGroups = {
    VP = {
        Teams = {
            -- Teams are populated safely below to avoid nil indices before DarkRP loads.
        },
        Permissions = {
            canCreateReport = true,
            canEditReport = true,
            canArchiveReport = false,
            canCreateBolo = true,
            canAddSecretNote = false,
            canViewSecretNote = false,
            canManageCases = true,
            canManageEvidence = true,
            canManageDutyLog = true,
            canManageBorder = true,
            canManageCustoms = true,
            canManageIncarcerations = true,
        },
    },
    VP_LEITUNG = {
        Teams = {
            -- Teams are populated safely below to avoid nil indices before DarkRP loads.
        },
        Permissions = {
            canCreateReport = true,
            canEditReport = true,
            canArchiveReport = true,
            canCreateBolo = true,
            canAddSecretNote = true,
            canViewSecretNote = true,
            canManageCases = true,
            canManageEvidence = true,
            canManageDutyLog = true,
            canManageBorder = true,
            canManageCustoms = true,
            canManageIncarcerations = true,
        },
    },
    MFS = {
        Teams = {
            -- Teams are populated safely below to avoid nil indices before DarkRP loads.
        },
        Permissions = {
            canCreateReport = true,
            canEditReport = true,
            canArchiveReport = true,
            canCreateBolo = true,
            canAddSecretNote = true,
            canViewSecretNote = true,
            canManageCases = true,
            canManageEvidence = true,
            canManageDutyLog = true,
            canManageBorder = true,
            canManageCustoms = true,
            canManageIncarcerations = true,
        },
    },
}

DDRPT.Config.ReportCategories = {
    "Diebstahl",
    "Sachbeschädigung",
    "Körperverletzung",
    "Staatsfeindliche Hetze",
    "Republikflucht",
    "Sonstiges",
}

DDRPT.Config.PriorityLevels = {
    "Niedrig",
    "Mittel",
    "Hoch",
}

DDRPT.Config.ReportStatuses = {
    "Neu",
    "In Bearbeitung",
    "Erledigt",
    "Archiviert",
}

DDRPT.Config.PersonTags = {
    "Republikfluchtverdacht",
    "Staatsfeindliche Hetze",
    "IM-Kontakt",
    "Überwachung",
}

DDRPT.Config.BoloDangerLevels = {
    "Niedrig",
    "Mittel",
    "Hoch",
    "Extrem",
}

DDRPT.Config.Pagination = {
    Reports = 20,
    Cases = 15,
    Evidence = 20,
    Duty = 25,
    Border = 20,
    Customs = 20,
    Incarcerations = 20,
    PeopleNotes = 20,
    Bolos = 20,
}

DDRPT.Config.NetRateLimits = {
    listReports = 0.5,
    createReport = 1,
    reportDetail = 0.5,
    reportUpdate = 0.5,
    addComment = 0.5,
    listCases = 0.5,
    createCase = 1,
    caseUpdate = 0.5,
    listPeople = 0.5,
    addPersonNote = 0.5,
    listBolos = 0.5,
    createBolo = 1,
    listEvidence = 0.5,
    createEvidence = 1,
    listDuty = 0.5,
    createDuty = 0.5,
    listBorder = 0.5,
    createBorder = 0.5,
    listCustoms = 0.5,
    createCustoms = 0.5,
    listIncarcerations = 0.5,
    createIncarcerations = 0.5,
}

DDRPT.Config.Notifications = {
    ReportHighPriorityRadio = true,
    BoloLoginNotice = true,
    BoloSpawnNotice = true,
    BoloSpawnCooldown = 60,
}

DDRPT.Config.DB = {
    Adapter = "mysqloo",
    Host = "127.0.0.1",
    User = "root",
    Pass = "",
    Database = "gmod",
    Port = 3306,
}

DDRPT.Config.BorderAccessTeams = {}
addTeam(DDRPT.Config.BorderAccessTeams, TEAM_POLICE)
addTeam(DDRPT.Config.BorderAccessTeams, TEAM_BORDER)

addTeam(DDRPT.Config.RoleGroups.VP.Teams, TEAM_POLICE)
addTeam(DDRPT.Config.RoleGroups.VP_LEITUNG.Teams, TEAM_CHIEF)
addTeam(DDRPT.Config.RoleGroups.MFS.Teams, TEAM_MFS)
