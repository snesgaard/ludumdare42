local textbox = require "ui/labelbox"
local icon = require "ui/icon"
local pimage = require "ui/pseudo_image"

local marker = {}

function marker:test()


    self:set_image(
        gfx.newImage("art/armor.png")
    )
    self:set_text("The Action")
end

function marker:create()
    self.icon = self:child(icon)
        :set_size(40, 40)
        :set_margin(3)
    self.text = self:child(textbox)
        :set_text("yo")
        :set_width(125)

    self:structure()
end

function marker:set_image(im)
    self.icon:set_image(im)
    self:structure()
    return self
end

function marker:set_text(text)
    self.text:set_text(text)
    self:structure()
    return self
end

function marker:structure(x, y)
    local base = self.icon:get_spatial():move(x or 0, y or 0)
    return {
        icon = base,
        text = self.text:get_spatial()
            :xalign(base, "left", "right")
            :yalign(base, "top", "top")
    }
end

function marker:draw(x, y)
    local struct = self:structure(x, y)
    self.icon:draw(struct.icon:pos())
    self.text:draw(struct.text:pos())
end

function marker:get_spatial()
    local s = self:structure()
    return Spatial.join(s.icon, s.text)
end

return marker
