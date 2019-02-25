local tileprops = {}

tileprops.tilesize = 32

tileprops.tiletypes = {
    grass = 1,
    dirt = 2,
    forest = 3,
    water = 4,
    mountain = 5,
    building = 6,
}

tileprops.tilecolor = {
    [tileprops.tiletypes.grass] = {0.6,0.8,0.4},
    [tileprops.tiletypes.dirt] = {150/255, 100/255, 50/255},
    [tileprops.tiletypes.forest] = {0/255, 100/255, 0/255},
    [tileprops.tiletypes.water] = {0.2, 0.3, 0.8},
    [tileprops.tiletypes.mountain] = {72/255, 26/255, 45/255},
}

tileprops.solid = {
    [tileprops.tiletypes.grass] = true, 
    [tileprops.tiletypes.dirt] = true,
    [tileprops.tiletypes.forest] = true, 
    [tileprops.tiletypes.water] = false,
    [tileprops.tiletypes.mountain] = false,
}

tileprops.tilemovement = {
    [tileprops.tiletypes.grass] = 0.5, 
    [tileprops.tiletypes.dirt] = 1,
    [tileprops.tiletypes.forest] = 1.5,
    [tileprops.tiletypes.water] = 0,
    [tileprops.tiletypes.mountain] = 0,
}


return tileprops