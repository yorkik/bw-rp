local policemdls = {
    'models/monolithservers/mpd/male_01.mdl',
    'models/monolithservers/mpd/male_01_2.mdl',
    'models/monolithservers/mpd/male_03.mdl',
    'models/monolithservers/mpd/male_03_2.mdl',
    'models/monolithservers/mpd/male_04.mdl',
    'models/monolithservers/mpd/male_04_2.mdl',
    'models/monolithservers/mpd/male_05.mdl',
    'models/monolithservers/mpd/male_05_2.mdl',
    'models/monolithservers/mpd/male_07.mdl',
    'models/monolithservers/mpd/male_07_2.mdl',
    'models/monolithservers/mpd/male_08.mdl',
    'models/monolithservers/mpd/male_08_2.mdl',
    'models/monolithservers/mpd/male_09.mdl',
    'models/monolithservers/mpd/male_09_2.mdl'
}

local policewep = {
    'weapon_handcuffs_key',
    'weapon_handcuffs',
    'weapon_taser',
    'weapon_hg_tonfa',
    'weapon_glock17',
    'weapon_walkie_talkie',
    'rp_notepad',
}

local swatwep = {
    'weapon_handcuffs_key',
    'weapon_handcuffs',
    'weapon_taser',
    'weapon_hg_tonfa',
    'weapon_glock17',
    'weapon_m4a1',
    'weapon_walkie_talkie',
    'rp_notepad',
}



TEAM_CITIZEN = rp.CreateClass{
    name = 'Гражданин',
    color = Color(0, 178, 0),
    model = {},
    weapons = {},
    ammo = {}
}

TEAM_POLICE = rp.CreateClass{
    name = 'Полицейский',
    color = Color(0, 0, 255),
    model = policemdls,
    weapons = policewep,
    ammo = {
        ["9x19 mm Parabellum"] = 30,
        ["Taser Cartridge"] = 5,
    }
}

TEAM_SWAT = rp.CreateClass{
    name = 'SWAT',
    color = Color(0, 0, 255),
    model = {'models/css_seb_swat/css_swat.mdl'},
    weapons = swatwep,
    ammo = {
        ["5.56x45 mm"] = 90,
        ["9x19 mm Parabellum"] = 30,
        ["Taser Cartridge"] = 5,
    }
}

cfg.civilprotection = {
    [rp.GetClassName(TEAM_POLICE)] = true,
    [rp.GetClassName(TEAM_SWAT)] = true,
}

cfg.swat = {
    [rp.GetClassName(TEAM_SWAT)] = true,
}

cfg.defaultjob = TEAM_CITIZEN