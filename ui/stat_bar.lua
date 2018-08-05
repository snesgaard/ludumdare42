local Label = require "ui/label"
local Bar   = require "ui/bar"
local Spatial = require "spatial"
local mutator = require "mutator"

local SpatialController = {}
SpatialController.__index = SpatialController


local StatBar = {}
StatBar.__index = StatBar

function StatBar:__tostring()
    return "CharacterBar"
end

function StatBar.create(self, id)
    self.id = id
    self.bar         = Bar.create()
    self.name_label  = Label.create()
        :set_align("left")
        :set_valign("bottom")
        :set_color(255, 255, 255)

    self.value_label = Label.create()
        :set_align("right")
        :set_valign("bottom")
        :set_color(255, 255, 255)

    self:set_spatial()
    self.spatial = mutator(self)
        :bind("pos", self.get_pos, self.set_pos)
    self:set_value(10, 10)

    self:update_stat()

    nodes.game.event.on_damage:listen(function(info)
        if info.defender == self.id then
            self:update_stat()
        end
    end)
    nodes.game.event.on_heal:listen(function(info)
        if info.target == self.id then
            self:update_stat()
        end
    end)
end

function StatBar:update_stat()
    local max_hp = nodes.game.actor.health.max[self.id] or 1
    local hp = nodes.game.actor.health.current[self.id] or 1
    self:set_value(hp, max_hp)
end

function StatBar:set_pos(p)
    return self:set_spatial(Spatial.create(p:unpack()))
end

function StatBar:get_pos()
    local root = self.name_label.spatial
    return vec2(root.x, root.y)
end

function StatBar:set_spatial(root)
    local w = 100
    root = root or Spatial.create()
    root = root:move(-w / 2, 0):set_size(w, 15)
    self.name_label.spatial = root
    self.value_label.spatial = root
    self.bar.spatial = root:move(0, 0, nil, "bottom"):set_size(nil, 5)
    return self
end

function StatBar:get_spatial()
    return Spatial.join(
        self.name_label.spatial, self.value_label.spatial, self.bar.spatial
    )
end

function StatBar:set_value(value, max_value)
    local text = string.format("%i / %i", value, max_value)
    self.value_label.text = text
    self.bar.value = value
    self.bar.max_value = max_value
    return self
end

function StatBar:set_name(name)
    self.name_label.text = name
    return self
end

function StatBar:draw(...)
    self.bar:draw(...)
    self.name_label:draw(...)
    self.value_label:draw(...)
end

return StatBar
