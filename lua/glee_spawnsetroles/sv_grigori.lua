-- roles for My Congregation, see hunters_glee's lua/glee_spawnsetroles/sv_rebels.lua for every field

local roles = {
    -- everyone's Father Grigori, and the shop's closed, so the slugs have to last
    ["grigori"] = {
        models = "models/player/monk.mdl",
        startWeapons = {
            {
                class = "termhunt_annabelle",
                purchaseClips = 30,
            },
        },
        defaultWeapons = {
            "weapon_fists"
        },
    },
}

GAMEMODE:GobbleRoles( roles )
