local Spatial = require "spatial"

local Label = {}
Label.__index = Label

function Label.create()
    local this = {
        text = "",
        spatial = Spatial.create(0, 0, 100, 100),
        color   = {0, 0, 0},
        valign = "center",
        align = "center",
        font = gfx.newFont(12)
    }
    return setmetatable(this, Label)
end

function Label:set_font(font)
    self.font = font
    return self
end

function Label:set_spatial(spatial)
    self.spatial = spatial
    return self
end

function Label:set_text(text)
    self.text = text
    return self
end

function Label:set_align(align)
    self.align = align
    return self
end

function Label:set_color(...)
    self.color = {...}
    return self
end

function Label:set_valign(valign)
    self.valign = valign
    return self
end

function Label:get_text_size(max_width, text)
    text = text or self.text
    local width, lines = self.font:getWrap(text, max_width)
    local height = self.font:getHeight() * #lines
    return width, height
end

function Label:draw(x, y, r, sx, sy)
    sx = sx or 1
    sy = sy or sx

    local _x, _y, w, h = self.spatial:unpack()
    local ew, eh = (sx - 1) * w, (sy - 1) * h
    _x, _y, w, h = self.spatial
        :expand(ew, eh)
        :unpack()
    if self.font then
        gfx.setFont(self.font)
    else
        gfx.setFont()
    end

    local tw, th = self:get_text_size(self.spatial.w)

    local font = gfx.getFont()
    if self.valign == "center" then
        y = y + h * 0.5 - th * 0.5 * sy
    elseif self.valign == "bottom" then
        y = y + h - th * sy
    end

    gfx.setColor(unpack(self.color))
    gfx.printf(
        self.text, _x + x, _y + y, w / sx, self.align, r, sx, sy
    )
end

return Label
