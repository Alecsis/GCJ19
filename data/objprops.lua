local objprops = {}

objprops.tilesize = 32*2

objprops.tiletypes = {
    mountain = 1,
    goal_blue = 2,
    goal_red = 3,
}

objprops.solid = {
  [objprops.tiletypes.mountain] = true,
  [objprops.tiletypes.goal_blue] = false,
  [objprops.tiletypes.goal_red] = false,
}

objprops.movement = {
  [objprops.tiletypes.mountain] = 10,
  [objprops.tiletypes.goal_blue] = 0,
  [objprops.tiletypes.goal_red] = 0,
}

objprops.imgpaths = {
  [objprops.tiletypes.mountain] = "assets/Tileset_Mountain.png",
  --[objprops.tiletypes.goal_blue] = "assets/Goal_Blue-export.png",
  --[objprops.tiletypes.goal_red] = "assets/Goal_Red-export.png",
  [objprops.tiletypes.goal_blue] = "assets/UI_Target_Shot.png",
  [objprops.tiletypes.goal_red] = "assets/UI_Target_Move.png",
}


return objprops