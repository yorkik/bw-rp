cfg.walkspeed = 160
cfg.runspeed = 320
cfg.jumppower = 200
cfg.chatdist = 500

cfg.defaultweapons = {
    'weapon_hands_sh',
    'rp_phone'
}

cfg.dootitems = {
    'weapon_physgun',
    'gmod_tool',
    'rp_keys'
}

cfg.disallowdrop = {
    ['weapon_hands_sh'] = true,
    ['rp_phone'] = true,

    ['weapon_physgun'] = true,
    ['gmod_tool'] = true,
    ['rp_keys'] = true,
}

cfg.hungerrate = 10
cfg.hungertake = 1

cfg.startmoney = 1500
cfg.tax = 0.07 -- 7%

cfg.minpins = 3
cfg.lockpickpns = 4

cfg.arresttime = 300
cfg.wantedtime = 600

cfg.orgcost = 2500
cfg.advertcost = 250

cfg.printdelay = 300
cfg.printamount = 500

cfg.laws = {
    ["Г.К"] = {
        { "11-10", "Прибытие на место" },
    },
    ["У.К"] = {
        { "10-1", "Слабый/плохой приём" },
    },
}



cfg.spawnzone = {
    ['rp_downtown_bw'] = {
        Vector(-3090.589844, -3531.529297, 175.352448),
        Vector(-1431.564453, -2805.436035, 559.746704)
    }
}

cfg.arrestpos = {
    ['rp_downtown_bw'] = {
        Vector(-2206.6267089844, -949.7197265625, 323.84124755859),
        Vector(-1906.6268310547, -950.66455078125, 323.84124755859),
        Vector(-1928.5576171875, -938.61254882813, 195.84124755859),
        Vector(-2221.1633300781, -940.5224609375, 195.84124755859),        
    }
}




cfg.defaultprice = 1000
cfg.doors = {
    {
        Name = "Дом №1",
        MapIDs = {3591, 3590, 3588},
    },
}