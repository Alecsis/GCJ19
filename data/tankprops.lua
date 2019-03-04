local tankprops = {}

tankprops.movement = 2
tankprops.range = 5
tankprops.health = 3
tankprops.vision = 3

tankprops.imgs = {"Assets/Ally_Spritesheet.png", "Assets/Enemy_Spritesheet.png"}

tankprops.spritesheet = {
    frame_width = 48,
    frame_height = 48,
    width = 12
}

tankprops.anim_types = {
    idle = 1,
    fire = 2,
    hit = 3,
    dead = 4,
}

tankprops.animations = {
    [tankprops.anim_types.idle] = {
        frames = {1, 2, 3, 4, 5, 6},
        speed = 1/8,
        next = tankprops.anim_types.idle,
    },
    [tankprops.anim_types.fire] = {
        frames = {13, 14, 15, 16, 17, 18},
        speed = 1/8,
        next = tankprops.anim_types.idle,
    },
    [tankprops.anim_types.hit] = {
        frames = {25, 26, 27, 28, 29},
        speed = 1/12,
        next = tankprops.anim_types.idle,
    },
    [tankprops.anim_types.dead] = {
        frames = {37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48},
        speed = 1/12,
        next = tankprops.anim_types.idle,
    },
}

tankprops.fire_pattern = {
    -- range 1
    {1, 0},
    {0, -1},
    {-1, 0},
    {0, 1},
    -- range 2
    {2, 0},
    {0, -2},
    {-2, 0},
    {0, 2},
    -- range 3
    {3, 0},
    {0, -3},
    {-3, 0},
    {0, 3}
}

return tankprops
