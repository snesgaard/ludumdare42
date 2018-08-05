local CharacterBar = require "ui/character_bar"
local Spatial = require "spatial"

local FactionBar = {}
FactionBar.__index = FactionBar

function FactionBar.create()
    local this = setmetatable({}, FactionBar)
    return this
end

function FactionBar:get_structure(size)
    if self.__structure then return self.__structure end

    local structure = Dictionary.create()

    --local w, h = 500, 30
    local inner_margin = 3
    inner_margin = inner_margin * 2
    structure.frames = self.__bars
        :map(
            function(bar)
                return bar:get_spatial():expand(inner_margin, inner_margin)
            end
        )
        :scan(
            function(prev, spatial)
                return spatial
                    :xalign(prev, "left", "left")
                    :yalign(prev, "bottom", "top", 5)
            end,
            Spatial.create(0, 5, 0, 0)
        )
    structure.bars = structure.frames
        :map(
            function(s)
                return s:expand(-inner_margin, -inner_margin):move(0, -1)
            end
        )
    structure.frames = structure.frames
        :map(function(f) return f:expand(15, 0, "left") end)

    self.__structure = structure
    return structure
end

function FactionBar:setup(gamestate)
    local heroes = gamestate:get("faction/")
        :filter(function(_, f) return f == "heroes" end)
        :keys()
        :sort(function(a, b)
            return gamestate:get("place/" .. a) < gamestate:get("place/" .. b)
        end)
    --local structure = self:get_structure(heroes:size())
    local bars = heroes:map(function(id)
        local bar = CharacterBar.create()
        local name = gamestate:get("name/" .. id)
        local hp   = gamestate:get("health/" .. id)
        local maxhp = gamestate:get("max_health/" .. id)
        bar.hp_bar:set_value(hp, maxhp)
        bar.name_label:set_text(name or "")
        return bar
    end)

    self.__bars = bars
    self.__heroes = heroes
    --self.__structure = structure
    return self
end

function FactionBar:on_damage(state, info)
    local id = info.dst
    local index = self.__heroes:argfind(id)
    if not index then return end
    local bar = self.__bars[index]
    local hp = state:get("health/" .. id)
    local maxhp = state:get("max_health/" .. id)
    bar.hp_bar:set_value(hp, maxhp)
end

function FactionBar:draw(x, y)
    gfx.push()
    gfx.translate(x, y)
    local structure = self:get_structure()
    for i = 1, self.__heroes:size() do
        local s = structure.bars[i]
        local b = self.__bars[i]
        local f = structure.frames[i]
        gfx.setColor(20, 30, 70, 200)
        gfx.rectangle("fill", f.x, f.y, f.w, f.h, 4)
        b:draw(s.x, s.y)
    end
    gfx.pop()
end

return FactionBar
