local Vec2 = require "vec2"
local dict = require "dictionary"
local Event      = require "event"
local Spatial    = require "spatial"

local rng = love.math.random

local Sprite = {}
Sprite.__index = Sprite

function Sprite.__tostring()
    return "Sprite"
end

function Sprite:draw(x, y, r, sx, sy)
    if not self.__draw_frame then return end
    gfx.setColor(unpack(self.color))
    local amp = self.shake_data.amp
    local phase = self.shake_data.phase
    x = x + self.spatial.x + math.sin(phase) * amp
    y = y + self.spatial.y
    sx = sx or 1
    sy = sy or 1
    sx = sx * self.scale
    sy = sy * self.scale
    self.atlas:draw(self.__draw_frame, self.origin, x, y, r, sx, sy)
end

function Sprite.__on_frame_progress() end

function Sprite:play(dt, frame_key)
    local frames = self.atlas:get_animation(frame_key)
    for i = 1, frames:size() do
        local f = frames[i]
        self.__draw_frame = f
        self.time = self.time + f.time
        self.__on_frame_progress(self, i, f)
        while self.time > 0 do
            self, dt = coroutine.yield()
            self.time = self.time - dt
        end
    end

    return dt
end

function Sprite:hide()
    Timer.tween(
        0.4,
        {
            [self.color] = {[4] = 0}
        }
    )
end

function Sprite:show()
    Timer.tween(
        0.4,
        {
            [self.color] = {[4] = 1}
        }
    )
end

function Sprite:shake(strong)
    if self.shake_data.tween then
        self.shake_data.tween:remove()
    end
    local s = rng() > 0.5 and 1 or -1
    self.shake_data.amp = strong and 15 or 5
    self.shake_data.phase = s * math.pi * 8
    self.shake_data.tween = Timer.tween(
        0.4,
        {
            [self.shake_data] = {amp = 0, phase = 0},
        }
    )
end

function Sprite:loop(dt, frame_key)
    while true do
        dt = self:play(dt, frame_key)
        self.on_loop()
    end
end

function Sprite:register(key, animation)
    self.__states[key] = animation
end

function Sprite:set_animation(a)
    local s = self.__states[a]
    if s then
        self.time = 0
        local prev_state = self.state
        self.state = s
        self.active = coroutine.wrap(
            function(sprite, dt)
                s(sprite, dt, prev_state)
                self.active = nil
            end
        )
    end
    return self
end

function Sprite:set_origin(origin)
    self.origin = origin
end

function Sprite:update(dt)
    if self.active then
        self.active(self, dt)
    end
    return self
end

function Sprite:attack_offset()
    return 0
end

function Sprite:set_color(r, g, b, a)
    self.color = {r or 1, g or 1, b or 1, a or 1}
    return self
end

function Sprite.create(atlas)
    local this = {
        time = 0,
        atlas = atlas,
        __states = {},
        active = nil,
        origin = 'origin',
        spatial = Spatial.create(),
        color = {1, 1, 1, 1},
        scale = 2,
        on_user = Event.create(),
        on_loop = Event.create(),
        shake_data = {amp = 0, phase = 0}
    }
    return setmetatable(this, Sprite)
end

return Sprite
