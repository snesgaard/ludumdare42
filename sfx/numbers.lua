local label = require "ui/label"
local Fonts = require "ui/fonts"

local number = {}

function number:create()
    self.label = label.create()
        :set_text("lelelel")
        :set_font(Fonts(25))
        :set_color(1, 1, 1)
        :set_align("center")
        :set_valign("center")

    self.scale = 5.0
    self.label.spatial = Spatial.create(0, 0, 0, 0)
        :expand(200, 50)
end

function number:__draw(x, y)
    self.label:draw(x, y, 0, self.scale, self.scale)
end

return number
