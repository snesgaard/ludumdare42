local StatBar = require "ui/stat_bar"
local Label   = require "ui/label"
local Square = require "ui/stat_square"
local Icon = require "ui/icon"
local Spatial = require "spatial"
local LabelBox = require "ui/labelbox"
local Frame = require "ui/frame"
local fonts = require "ui/fonts"

local StatIcon = {}

function StatIcon:create(type, id)
    local type2path = {
        power = "art/power.png",
        armor = "art/armor.png",
        charge = "art/charge.png",
        shield = "art/shield.png",
        agility = "art/agility.png",
    }
    path = type2path[type]

    self.id = id
    self.icon = self:child(Icon)
        :set_image(gfx.newImage(path))
        :set_im_color(1, 1, 1, 0.7)
        :set_margin(2)
        :set_size(16, 16)
    self.icon.frame
        :set_corner(3)
        :set_color(0, 0, 0, 0)

    local box_spatial = Spatial.create(0, 0, 14, 14)
        :xalign(self.icon:get_spatial(), "center", "center")
        :yalign(self.icon:get_spatial(), "top", "bottom")
        :move(0, 0)

    self.stat_label = Label.create()
        :set_spatial(box_spatial)
        :set_text("F")
        :set_color(1, 1, 1, 1)
        :set_font(gfx.newFont(12))
    self.stat_box = Frame.create()
        :set_spatial(box_spatial)
        :set_corner(2)
        :set_color(1, 1, 1, 1)

    self:set_value(0)

    local function callback(id, value)
        self:set_value(value)
    end

    self.monitor = nodes.game:monitor_stat(type, callback, id)
end

local function interpolate_color(value, color)
    value = math.abs(value)

    local s = value / 9.0
    s = s * 0.25 + 0.75
    local c = {}

    for i, v in ipairs(color) do
        c[i] = (1 - s) + v * s
    end
    return c
end

function StatIcon:set_value(value)
    value = value or 0
    local text = string.format("%i", value)
    local color = value >= 0 and {1, 0.6, 0.4} or {0.6, 0.5, 1}
    --color = interpolate_color(value, color)
    if value == 0 or true then
        color = {1, 1, 1}
    end
    self.stat_label:set_text(text)
    self.stat_box:set_color(unpack(color))
    --self.icon.frame:set_color(unpack(color))
    return self
end

function StatIcon:__draw(x, y)
    --self.stat_box:draw(x, y)
    self.icon:draw(x, y)
    self.stat_label:draw(x, y)
end

function StatIcon:get_spatial()
    return Spatial.join(
        self.icon:get_spatial(), self.stat_box.spatial
    )
end

local CharacterBar = {}

function CharacterBar.create(self, id)
    self.stat_bar = self:child(StatBar, id)
    self.stat_bar:set_spatial(
        self.stat_bar:get_spatial()
            :compile()
            :move(50, -30)
    )
    self.stat_squares = list(
        self:child(StatIcon, "power", id),
        --self:child(StatIcon, "charge"):set_value(-1),
        self:child(StatIcon, "armor", id),
        --self:child(StatIcon, "shield"):set_value(-9),
        self:child(StatIcon, "agility", id)
    )


    self.structure = list(
        self.stat_squares:head():get_spatial()
    )

    for i = 2, self.stat_squares:size() do
        local prev = self.structure[i - 1]
        self.structure[i] = prev:move(10, 0, "right")
    end

    self.structure = Spatial.join(self.structure:unpack())

    self.structure = self.structure
        :xalign(self.stat_bar:get_spatial(), "center", "center")
        :yalign(self.stat_bar:get_spatial(), "top", "bottom", 7)

    self.border = Spatial.join(
        self.stat_bar:get_spatial(), list(self.structure):unpack()
    ):compile():expand(20, 10)
    self.bg_frame = Frame.create()
        :set_spatial(self.border)
        :set_color(0.0, 0.0, 0.2, 0.3)
        :set_corner(15)
end

function CharacterBar:set_spatial(root)

end

function CharacterBar:get_spatial()

end

function CharacterBar:hide()
    self.hidden = true
    return self
end

function CharacterBar:show()
    self.hidden = false
    return self
end

function CharacterBar:draw(x, y)
    if self.hidden then return end
    x = x or 0
    y = y or 0
    self.bg_frame:draw(x, y)
    self.stat_bar:draw(x, y)

    for i, square in ipairs(self.stat_squares) do
        local spatial = self.structure.items[i]
        local _x, _y = spatial:unpack()
        square:draw(x + _x, y + _y)
    end
end

return CharacterBar
