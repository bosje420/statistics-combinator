


local function deepmerge(t,o)
    for k,v in pairs(o) do
        if type(v) == 'table' and type(t[k]) == 'table' then
            v = deepmerge(t[k], v)
        end
        t[k] = v
    end
    return t
end

local function set(t,k,v) t[k] = v return t end

local function rm_prop(key, entity)
    return set(entity,key,nil)
end

local function rm_icon(entity)
    return rm_prop('icon', rm_prop('icon_size', entity))
end

local function iter_layers(entity, f)
    for _, sprite in pairs(entity.sprites or {}) do
        if sprite.layers then
            iter_layers({sprites=sprite.layers}, f)
        else
            f(sprite)
            if sprite.hr_version then
                f(sprite.hr_version)
            end
        end
    end
    return entity
end



--------------------------------------------------------------------------------

local color = {
    yellow = {r=1,g=1,b=0,a=1},
    green = {r=0,g=1,b=0,a=1},
    blue = {r=0,g=0,b=1,a=1},
    dark   = {r=0,g=0,b=0,a=1},
}

local hidden = {"placeable-neutral", "not-deconstructable", "not-blueprintable", "not-on-map", "hide-alt-info", "hidden", "no-copy-paste", "not-in-kill-statistics"}

local transparent = {
    filename = "__statistics-combinator__/graphics/transparent.png",
    priority = "extra-high",
    width = 1,
    height = 1,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 1,
}




local steam = data.raw['fluid']['steam']
local cc = data.raw["constant-combinator"]["constant-combinator"]


local icons = {
    internal = {
        {icon = steam.icon, icon_size = steam.icon_size, tint = color.yellow},
    },
    combinator = {
        {icon = cc.icon, icon_size = cc.icon_size, tint = color.green},
    },
    combinator2 = {
        {icon = cc.icon, icon_size = cc.icon_size, tint = color.blue},
    },
}

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = "production-combinator"
entity.minable.result = "production-combinator"
entity.item_slot_count = 5
entity.sprites.tint = color.green
data:extend{entity}
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = "consumption-combinator"
entity.minable.result = "consumption-combinator"
entity.item_slot_count = 5
entity.sprites.tint = color.blue
data:extend{entity}

data:extend{



   

    -- item ----------------------------------------------------------------


    rm_icon(deepmerge(table.deepcopy(data.raw.item["constant-combinator"]), {
        name = "production-combinator",
        place_result = "production-combinator",
        order = "c[combinators]-c[constant-combinator]-a[production-combinator]",
        icons = icons.combinator,
    })),

    rm_icon(deepmerge(table.deepcopy(data.raw.item["constant-combinator"]), {
        name = "consumption-combinator",
        place_result = "consumption-combinator",
        order = "c[combinators]-c[constant-combinator]-b[consumption-combinator]",
        icons = icons.combinator2,
    })),


    -- recipe --------------------------------------------------------------


    {   type = "recipe",
        name = "production-combinator",
        energy_required = 30,
        ingredients = {
            {"red-wire", 2},
            {"constant-combinator", 2},
            {"advanced-circuit", 4},
        },
        result = "production-combinator",
        enabled = false,
    },

    {   type = "recipe",
        name = "consumption-combinator",
        energy_required = 30,
        ingredients = {
            {"green-wire", 2},
            {"constant-combinator", 2},
            {"advanced-circuit", 4},
        },
        result = "consumption-combinator",
        enabled = false,
    },


    -- technology ----------------------------------------------------------


    {   type = "technology",
        name = "statistics-combinator",
        prerequisites = {
            "circuit-network",
            "electric-energy-distribution-1",
            "optics",
        },
        icon = "__statistics-combinator__/graphics/technology.png",
        icon_size = 128,
        order = "a-h-d-a",
        effects = {
            {type = "unlock-recipe", recipe = "production-combinator"},
            {type = "unlock-recipe", recipe = "consumption-combinator"},
        },
        unit = {
            time = 30,
            count = 50,
            ingredients = {
                {"automation-science-pack", 1},
                {  "logistic-science-pack", 1},
            },
        },
    },

   







   





}


