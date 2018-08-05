local Spatial = require "spatial"

local Frame = {}
Frame.__index = Frame

function Frame.create()
    local this = {
        spatial = Spatial.create(0, 0, 0, 0),
        border_spatial = Spatial.create(0, 0, 0, 0),
        corner = 5,
        border = 0,
        color = {1, 1, 1},
        border_color = {0.5, 0.5, 0.5}
    }
    return setmetatable(this, Frame)
end

function Frame:set_color(r, g, b, a)
    self.color = {r, g, b, a}
    return self
end
function Frame:set_spatial(spatial)
    self.spatial = spatial
    self.border_spatial = spatial:expand(self.border, self.border)
    return self
end
function Frame:set_corner(corner)
    self.corner = corner
    return self
end

function Frame:get_spatial()
    return self.border_spatial
end

function Frame:set_border(border)
    self.border = border
    self.border_spatial = self.spatial:expand(self.border, self.border)
    return self
end

function Frame:draw(x, y)
    x = x or 0
    y = y or 0
    gfx.setColor(unpack(self.color))
    local _x, _y, w, h = self.spatial:unpack()
    gfx.rectangle("fill", x + _x, y + _y, w, h, self.corner)
end

return Frame
