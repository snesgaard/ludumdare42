local Atlas = require "atlas"
local Sprite = require "animation/sprite"
local blast = require "actor/blast"
local id_gen = require "id_gen"

local function spawn_rock(spatial)
    local bid = id_gen.register("blast")

    nodes.level:spawn(blast, bid, spatial)

    return bid
end

local attacks = {}

function attacks.__get_ground_cast(id)
    local s = visual.sprite[id]
    local anchor = s.atlas:get_hitbox("mean_wizard_gcast", "cast")
    local o = s.atlas:get_hitbox("mean_wizard_gcast", "origin")
    local pos = get_stat("spatial", id)
    local face = get_stat("face", id)

    anchor = anchor:move(pos.x - o.x, pos.y - o.y)

    if face and face < 0 then
        return anchor:hmirror(pos), pos
    else
        return anchor, pos
    end
end

function attacks.clear_rocks(id)
    local pos = get_stat("spatial", id):expand(100, 50)

    local is, ie = nodes.level:rectangle(pos:unpack())

    for x = is.x, ie.x do
        for y = is.y, ie.y do
            nodes.level:remove_tile(x, y)
        end
    end
end

function attacks.single_ground(id)
    local cast_box, pos = attacks.__get_ground_cast(id)
    local s = spatial(20, 20, 50, 100)
        :xalign(cast_box, "right", "right")
        :yalign(pos, "bottom", "bottom")
        :move(0, -10)
    local bid = spawn_rock(s)

    local target = nodes.level:get_player()
    local tpos = get_stat("spatial", target)


    local dir = vec2(tpos:center()) - vec2(s:center())
    dir = dir:normalize() * 500
    dir.y = math.min(2, dir.y)

    set_stat("speed", bid, dir)
end

function attacks.lop_ground(id)
    local cast_box, pos = attacks.__get_ground_cast(id)
    local s = spatial(20, 20, 20, 20)
        :xalign(cast_box, "right", "right")
        :yalign(pos, "bottom", "bottom")
        :move(0, -10)
    local bid = spawn_rock(s)
    local rng = love.math.random
    local vx = rng(200, 600)
    if rng() > 0.5 then
        vx = -vx
    end
    set_stat("speed", bid, vec2(vx, rng(-1000, -2500)))
    set_stat("gravity", bid, vec2(0, 6000))
end

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "mean_wizard_idle")
end

function animations.float(sprite, dt)
    sprite:loop(dt, "mean_wizard_float")
end

function animations.chant(sprite, dt)
    sprite:loop(dt, "mean_wizard_gcast/chant")
end

function animations.cast(sprite, dt)
    sprite:play(dt, "mean_wizard_gcast/precast")
    sprite.events.on_cast()
    sprite:loop(dt, "mean_wizard_gcast/cast")
end


function create_sprite(atlas)
    local sprite = Sprite.create(atlas)
    for key, anime in pairs(animations) do
        sprite:register(key, anime)
    end
    sprite.events = {
        on_cast = event()
    }
    return sprite
end

local ai = {}

function ai:create(id)

    self:fork(ai.test, id)
end

function ai.test(self, id)
    self:wait(0.1)
    while true do
        local s = visual.sprite[id]
        s:set_animation("chant")
        self:wait(1.0)
        s:set_animation("cast")
        for i = 1, 20 do
            attacks.lop_ground(id)
            self:wait(0.25)
        end
        s:set_animation("idle")
        self:wait(1.0)
        attacks.clear_rocks(id)
    end
end


local wizard = {}

function wizard.state(id, s, props)
    local x, y = s.x, s.y
    local function get_boundary()
        local a = load_atlas('assets/sprites/')
        if not a then
            return spatial(x, y, 10, 10)
        end

        local frames = a:get_animation("mean_wizard_idle")
        local origin = frames:head().hitbox.origin

        return spatial(x, y, origin.w, origin.h)
            :yalign(s, "bottom", "bottom")
    end


    nodes.actor_state:set_stat("spatial", id, get_boundary())
    set_stat("health/current", id, 20)
    set_stat("health/max", id, 20)
    set_stat("gravity", id, vec2(0, 3000))
    set_stat("faction", id, -1)

    local p = process.create(ai, id)
    nodes.actor_state:set_stat("script", id, p)
end

function wizard.visual(id)
    visual.sprite[id] = create_sprite(load_atlas('assets/sprites/'))
    visual.sprite[id]:set_animation("idle")
end

return wizard
