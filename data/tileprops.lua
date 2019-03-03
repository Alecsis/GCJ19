local tileprops = {}

tileprops.tilesize = 32*2

tileprops.tiletypes = {
  grass = 1,
  sand = 2,
  forest = 3,
  water = 4,
  mountain = 5,
  building = 6,
}

tileprops.tilecolor = {
  [tileprops.tiletypes.grass] = {0.6,0.8,0.4},
  [tileprops.tiletypes.sand] = {150/255, 100/255, 50/255},
  [tileprops.tiletypes.forest] = {0/255, 100/255, 0/255},
  [tileprops.tiletypes.water] = {51/255, 153/255, 255/255},
  [tileprops.tiletypes.mountain] = {72/255, 26/255, 45/255},
}

tileprops.solid = {
  [tileprops.tiletypes.grass] = false, 
  [tileprops.tiletypes.sand] = true,
  [tileprops.tiletypes.forest] = true, 
  [tileprops.tiletypes.water] = false,
  [tileprops.tiletypes.mountain] = false,
}

tileprops.tilemovement = {
  [tileprops.tiletypes.grass] = 1, 
  [tileprops.tiletypes.sand] = 1,
  [tileprops.tiletypes.forest] = 1.5,
  [tileprops.tiletypes.water] = 3,
  [tileprops.tiletypes.mountain] = 10,
}

tileprops.imgpaths = {
  [tileprops.tiletypes.grass] = "assets/Tileset_Grass-export.png", 
  [tileprops.tiletypes.sand] = "assets/Tileset_Sand.png",
  [tileprops.tiletypes.water] = "assets/Tileset_Water-export.png",
  [tileprops.tiletypes.mountain] = "assets/Tileset_Mountain.png",
}


return tileprops