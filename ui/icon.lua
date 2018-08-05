local Frame = require "ui/frame"
local Spatial = require "spatial"

local Icon = {}
Icon.__index = Icon

-- TODO CHange this so that it has a fixed size
function Icon:test()
    self:set_image(gfx.newImage("art/armor.png"))
        :set_color(1, 1, 1, 0.5)
end

function Icon:create()
    self.frame = Frame.create():set_color(0.55, 0.55, 0.55)
    self.margin = 2
    self.color = {1, 1, 1, 1}
    self.size = vec2(32, 32)
end

function Icon:set_color(...)
    self.frame:set_color(...)
    return self
end

function Icon:set_im_color(r, g, b, a)
    self.color = {r, g, b, a}
    return self
end

function Icon:set_margin(margin)
    self.margin = margin
    self:clear_structure()
    return self
end

function Icon:set_image(im)
    self.im = im
    self:clear_structure()
    return self
end

function Icon:set_size(x, y)
    self.size.x = x
    self.size.y = y
    self:clear_structure()
    return self
end

function Icon:clear_structure()
    self.__structure = nil
end

function Icon:get_structure()
    if self.__structure then return self.__structure end

    local structure = Dictionary.create()
    structure.image = Spatial.create(
        0, 0, self.size:unpack()
    )
    structure.frame = structure.image
        :expand(self.margin * 2, self.margin * 2)
        :move(self.margin, self.margin)
    structure.image = structure.frame
        :expand(-self.margin * 2, -self.margin * 2)

    self.frame.spatial = structure.frame

    self.__structure = structure
    return self.__structure
end

function Icon:set_margin(margin)
    self.margin = margin
    self:clear_structure()
    return self
end

function Icon:get_spatial()
    local structure = self:get_structure()
    return structure.frame
end

function Icon:set_spatial(s)
    self.pos = vec2(s.x, s.y)
    self:clear_structure()
    return self
end

function Icon:__draw(x, y, r, sx, sy)
    x = x or 0
    y = y or 0
    sx = sx or 1
    sy = sy or 1
    local s = self:get_structure()
    self.frame.spatial = s.frame
    self.frame:draw(x, y)
    gfx.setColor(unpack(self.color))

    local function im_draw()
        if not self.im then return end

        if type(self.im) == "function" then
            self.im(
                x + s.image.x, y + s.image.y, self.size.x, self.size.y, r,
                sx, sy
            )
        else
            sx = sx * self.size.x / self.im:getWidth()
            sy = sy * self.size.y / self.im:getHeight()
            gfx.draw(
                self.im, x + s.image.x, y + s.image.y, r, sx, sy
            )
        end
    end

    im_draw()
end

return Icon
