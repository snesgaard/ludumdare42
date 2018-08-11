local Atlas = require "atlas"
local Sprite = require "animation/sprite"

local animations = {}

function animations.idle(sprite, dt)
    sprite:loop(dt, "test")
end

function create_sprite(atlas)
    local sprite = Sprite.create(atlas)
    for key, anime in pairs(animations) do
        sprite:register(key, anime)
    end
    return sprite
end

local ai = {}

function ai:create(id)
    set_stat("tile/collision/y", id, self:set_earth())
    self:fork(self.listen_for_jump)
end

function ai:set_earth()
    return function()
        self.earth = love.timer.getTime()
    end
end

function ai:__update(dt, id)
    local speed = get_stat("speed", id) or vec2(0, 0)
    local sx = 600

    speed.x = 0

    if love.keyboard.isDown("left") then
        speed.x = speed.x - sx
    end
    if love.keyboard.isDown("right") then
        speed.x = speed.x + sx
    end

    local function attack()
        local aid = id .. "attack"
        local s = get_stat("spatial", id)
        return aid, s:xalign(s, "left", "right"):set_size(10, 10)
    end

    if love.keyboard.isDown("a") then
        local function callback(id, x, y, type)
            nodes.level:remove_tile(x, y)
        end

        local aid, s = attack()
        set_stat("spatial", aid, s)
        set_stat("tile/collision/tile", aid, callback)
    else
        local aid, s = attack()
        set_stat("spatial", aid)
    end

    local function handle_jump()
        local e = self.earth
        local j = self.jump

        if not e or not j then
            return
        elseif math.abs(e - j) < 0.2 then
            self.earth = nil
            self.jump = nil
            speed.y = -2000
        end
    end

    handle_jump()

    set_stat("speed", id, speed)
end

function ai:listen_for_jump(id)
    local key = self:wait(nodes.root.keypressed)
    if key == "space" then
        self.jump = love.timer.getTime()
    end
    return self:listen_for_jump(id)
end

local test = {}

function test.__id(t)
end

function test.state(id, s, props)
    local x, y = s.x, s.y
    local function get_boundary()
        local a = load_atlas('assets/sprites/')
        if not a then
            return spatial(x, y, 10, 10)
        end

        local frames = a:get_animation("test")
        local origin = frames:head().hitbox.origin
        return spatial(x, y, origin.w, origin.h)
    end

    local p = process.create(ai, id)

    nodes.actor_state:set_stat("spatial", id, get_boundary())
    nodes.actor_state:set_stat("script", id, p)
end

function test.visual(id)
    visual.sprite[id] = create_sprite(load_atlas('assets/sprites/'))
    visual.sprite[id]:set_animation("idle")
end

return test
