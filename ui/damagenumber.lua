local Label = require "ui/label"
local Fonts = require "ui/fonts"
local Spatial = require "spatial"
local statup = require "sfx/stat_up"

local DamageNumber = {}
DamageNumber.__index = DamageNumber

function DamageNumber:create(number, master, type)
    local type2color = {
        heal = {50, 255, 120, 0},
        default = {255, 120, 50, 0},
        crit = {255, 50, 20, 0}
    }

    local color = type2color[type] or type2color.default
    for i, c in ipairs(color) do
        color[i] = c / 255
    end
    self.label = Label.create()
        :set_text(tostring(number))
        :set_color(unpack(color))
        :set_font(Fonts(25))
        :set_align("center")
        :set_valign("center")

    local type2scale = {
        default = 1,
        crit = 1,
    }
    self.scale = 5
    self.end_scale = type2scale[type] or type2scale.default
    self.master = master

    self.label.spatial = Spatial.create(0, 0, 0, 0)
        :expand(200, 50)
    self:fork(DamageNumber.animate)
end

function DamageNumber.animate(self)
    local tween = Timer.tween(0.15, {
        [self.label.color] = {[4] = 255},
        [self] = {scale = self.end_scale}
    })
    self:wait(tween)
    self:wait(1)
    local spatial = self.label.spatial
    tween = Timer.tween(0.25, {
        [self.label.color] = {[4] = 0},
        [self.label.spatial] = spatial:move(0, -50)
    })
    self:wait(tween)
    self:remove()
end

function DamageNumber:remove()
    --self.animation:terminate()
    self.master:remove(self)
end

function DamageNumber:draw(x, y, r)
    self.label:draw(x, y, r, self.scale, self.scale)
end

local DamageNumberServer = {}
DamageNumberServer.__index = DamageNumberServer

function DamageNumberServer:create()
    self.numbers = {}
    self.x = {}
    self.y = {}
    self.time = {}
    self.draworder = {}

    nodes.game.event.on_damage:listen(function(info)
        local id = info.defender
        local dmg = info.damage

        local pos = nodes.position:get_world(id) - vec2(0, 100)
        if info.miss then
            self:number("Miss", pos.x, pos.y)
        elseif info.shielded then
            self:number("Void", pos.x, pos.y)
        elseif info.crit then
            dmg = tostring(dmg) .. "\nCritical"
            self:number(dmg, pos.x, pos.y, "crit")
        else
            self:number(dmg, pos.x, pos.y)
        end
    end)


    nodes.game.event.on_heal:listen(function(info)
        local pos = nodes.position:get_world(info.target) - vec2(0, 150)
        self:number(info.heal, pos.x, pos.y, "heal")
    end)

    self.icons = {
        armor = gfx.newImage("art/armor.png"),
        power = gfx.newImage("art/power.png"),
        agility = gfx.newImage("art/agility.png"),
    }

    for _, stat in pairs({"armor", "power", "agility"}) do
        nodes.game:monitor_stat(stat, function(id, value, prev)
            if value == prev then return end
            local im = self.icons[stat]
            local pos = nodes.position:get_world(id)
            self:child(statup, value > prev)
                :set_im(im)
                :set_origin(pos - vec2(0, 50))
                :set_value(math.abs(value - prev))
        end)
    end
end

function DamageNumberServer:number(number, x, y, type)
    number = process.create(DamageNumber, number, self, type)
    --number = DamageNumber.create(number, self, type)
    self.numbers[number] = true
    self.time[number] = love.timer.getTime()
    self.x[number] = x + love.math.random(-10, 10)
    self.y[number] = y + love.math.random(-10, 10)
    self.draworder = self:get_draworder()
    return self
end

function DamageNumberServer:remove(number)
    self.numbers[number] = nil
    self.time[number] = nil
    self.x[number] = nil
    self.y[number] = nil
    self.draworder = self:get_draworder()
    return self
end

function DamageNumberServer:__update(dt)
    for number, _ in pairs(self.numbers) do
        number:update(dt)
    end
end

function DamageNumberServer:get_draworder()
    local order = List.create()
    for number, _ in pairs(self.numbers) do
        order[#order + 1] = number
    end
    local function sort(a, b)
        return self.time[a] < self.time[b]
    end
    table.sort(order, sort)
    return order
end

function DamageNumberServer:__draw(x, y, r)
    x = x or 0
    y = y or 0
    for _, number in ipairs(self.draworder) do
        number:draw(self.x[number] + x, self.y[number] + y, r)
    end
end

return DamageNumberServer
