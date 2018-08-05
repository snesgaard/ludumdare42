local spatial = require "spatial"
local label = require "ui/label"

local square = {}

function square:create()
    self.main_box = spatial.create(0, 0, 16, 16)
    self.num_box = spatial.create(0, 0, 12, 12)
        :xalign(self.main_box, "center", "right")
        :yalign(self.main_box, "center", "bottom")

    self.main_box = label.create():set_spatial(self.main_box)
end

function square:__draw(x, y)
    gfx.push()
    gfx.translate(x, y)
    gfx.setColor(1, 1, 1)
    self.main_box:draw(0, 0)
    gfx.setColor(1, 1, 1)
    gfx.rectangle(
        "fill", self.num_box.x, self.num_box.y,
        self.num_box.w,
        self.num_box.h, 3
    )
    gfx.pop()
end

function square:get_spatial()
    return Spatial.border(self.main_box.spatial, self.num_box)
end

return square
