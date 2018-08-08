local sti = require "modules/sti"
local tilemap = require "physics/tilemap"

local level = {}

function level:create(path)
    self.visual = sti(path)
    self.physics = tilemap.from_tiled(self.visual, "Tile Layer 1")

    for _, l in ipairs(self.visual.layers) do
        l.opacity = l.type == "tilelayer" and 1 or 0
    end

    self:__init_actors(self.visual)
end

function level:__init_actors(map)
    local layer = map.layers["actors"]
    for _, obj in pairs(layer.objects) do
        local act = require("actor/" .. obj.type)
        if act.state then
            act.state("foo", obj.x, obj.y)
        end
        if act.visual then
            act.visual("foo")
        end
    end
end

function level:__update_physics()

end

function level:__draw(x, y)
    self.visual:draw(x, y)
end

return level
