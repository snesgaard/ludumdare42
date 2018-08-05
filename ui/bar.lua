local math = require "math"
local Spatial = require "spatial"

local Bar = {}
Bar.__index = Bar

function Bar.create()
    local this = {
        spatial = Spatial.create(0, 0, 100, 10),
        value = 0,
        max_value = 100,
        align = "right"
    }
    return setmetatable(this, Bar)
end

function Bar:set_value(value)
    self.value = math.min(value, self.max_value)
    return self
end

function Bar:set_align(align)
    self.align = align
    return self
end

function Bar:draw(x, y)
    x = self.spatial.x + x
    y = self.spatial.y + y
    local w, h = self.spatial.w, self.spatial.h
    gfx.setColor(0, 0, 0, 0.4)
    gfx.rectangle("fill", x, y, w, h)
    gfx.setColor(255, 255, 255)
    local s = self.value / self.max_value
    if align == "right" then
        x = x + w * (1 - s)
    end
    gfx.rectangle("fill", x, y, s * w, h)
end

return Bar
