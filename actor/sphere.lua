local Atlas = require "atlas"
local Sprite = require "animation/sprite"
local blast = require "actor/blast"
local id_gen = require "id_gen"

local function spawn_rock(id, spatial, speed, gravity, box)
    box = box or "spawn_y"
    local s = visual.sprite[id]
    local anchor = s.atlas:get_hitbox("sphere", box)

    local pos = get_stat("spatial", id)
    anchor = anchor:move(pos.x, pos.y)

    local bid = id_gen.register("blast")

    if box == "spawn_y" then
        spatial = spatial:yalign(anchor, "top", "top")
            :xalign(anchor, "center", "center")
    else
        spatial = spatial:yalign(anchor, "center", "center")
            :xalign(anchor, "left", "left")
    end

    nodes.level:spawn(blast, bid, spatial)
    set_stat("speed", bid, vec2(0, 500))

    return bid
end

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "sphere")
end

function create_sprite(atlas)
    local sprite = Sprite.create(atlas)
    for key, anime in pairs(animations) do
        sprite:register(key, anime)
    end
    sprite.events = {
        hit = event()
    }
    return sprite
end

local ai = {}

function ai:create(id)
    self:set_state(ai.test, id)
end

ai.test = {}

function ai.test.enter(self, id)
    self:fork(ai.test.throw_rocks, id)
end

function ai.test.throw_rocks(self, id)
    self:wait(0.1)
    while true do
        spawn_rock(id, spatial(0, 0, 100, 10), vec2(0, 1000), vec2(0, 0), "spawn_x")
        self:wait(1.0)
    end
end

local sphere = {}

function sphere.state(id, s, prop)
    local x, y = s.x, s.y
    local function get_boundary()
        local a = load_atlas('assets/sprites/')
        if not a then
            return spatial(x, y, 10, 10)
        end

        local frames = a:get_animation("sphere")
        local origin = frames:head().hitbox.origin

        return spatial(x, y, origin.w, origin.h)
            :yalign(s, "bottom", "bottom")
    end

    nodes.actor_state:set_stat("spatial", id, get_boundary())
    --set_stat("gravity", id, vec2(0, 0))
    set_stat("script", id, process.create(ai, id))
    set_stat("health/current", id, 8)
    set_stat("health/max", id, 8)
end

function sphere.visual(id)
    visual.sprite[id] = create_sprite(load_atlas('assets/sprites/'))
    visual.sprite[id]:set_animation("idle")
end

return sphere
