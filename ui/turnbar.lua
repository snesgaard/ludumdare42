local Spatial = require "spatial"
local Animation = require "animation/server"

local Icon = {}
Icon.__index = Icon

function Icon.get_spatial()
    return Spatial.create(0, 0, 50, 50)
end

function Icon.create()
    local this = {
        icon = nil,
        color = {255, 255, 255, 255}
    }
    this = setmetatable(this, Icon)
    this:set_spatial(Icon.get_spatial())
    return this
end

function Icon:set_spatial(spatial)
    self.spatial = spatial
    return self
end

function Icon:set_icon(icon)
    self.icon = icon
    return self
end

function Icon:set_color(r, g, b, a)
    self.color = {r, g, b, a}
    return self
end

function Icon:draw(x, y)
    local a = self.color[4]
    local s = self.spatial
    gfx.stencil(function()
        gfx.setColorMask()
        --gfx.setColor(unpack(self.color))
        local w = 1.5
        gfx.setColor(20 * w, 30 * w, 70 * w, a)
        gfx.rectangle("fill", s.x + x, s.y + y, s.w, s.h, 8)
    end, "replace", 1)
    --gfx.setStencilTest("equal", 1)
    gfx.setColor(255, 255, 255, a * 255 / 150)
    if self.icon then
        self.icon(s.x + x + 25, s.y + y + 50, 0, 2, 2)
    end
    gfx.setStencilTest("equal", 0)
    gfx.setColor(20, 30, 70, a)
    local f = s:expand(6, 6)
    --gfx.rectangle("fill", f.x + x, f.y + y, f.w, f.h, 2)
    gfx.setStencilTest()
    return self
end

local TurnBar = {}
TurnBar.__index = TurnBar

function TurnBar.create()
    local this = {
        filled_actors = List.create(),
        empty_actors = List.create(),
        leaving_actors = List.create(),
        actions = Dictionary.create(),
        targets = Dictionary.create(),
        __group = {
            anime = {},
            tween = {},
        },
        xmargin = 30,
        ymargin = 10,
    }
    return setmetatable(this, TurnBar)
end

function TurnBar:clear()
    for _, icon in pairs(self.filled_actors.concat(self.empty_actors)) do
        self.actions[icon] = nil
        self.targets[icon] = nil
    end
    self.filled_actors = List.create()
    self.empty_actors = List.create()
end

function TurnBar:__structure()
    local spatial = Icon.get_spatial()
    local structure = {}
    for _, s in ipairs(self.filled_actors) do
        structure[s] = spatial
        spatial = spatial:move(self.xmargin, 0, "right")
    end
    for _, s in pairs(self.empty_actors) do
        structure[s] = spatial
        spatial = spatial:move(self.xmargin, 0, "right")
    end
    return structure
end

function TurnBar:actor(visualstate, id)
    print(visualstate, id, visualstate.icon.color[id])
    local icon_im = visualstate.icon.color[id]
    local icon = Icon.create()
        :set_color(200, 200, 255, 0)
        :set_icon(icon_im)
    self.empty_actors = self.empty_actors:insert(icon)
    local structure = self:__structure()
    local final_pos = structure[icon]
    icon.spatial = final_pos:move(400, 0)
    icon.tween = Timer.tween(0.25, {
        [icon.spatial] = final_pos,
        [icon.color] = {[4] = 200}
    }):group(self.__group.tween)
    return self
end

function TurnBar:action(action)
    local icon = self.empty_actors:head()
    if not icon then return self end
    self.empty_actors = self.empty_actors:body()
    self.filled_actors = self.filled_actors:insert(icon)
    local structure = self:__structure()
    local spatial = structure[icon]
    spatial = spatial:yalign(spatial, "top", "bottom", self.ymargin)
    local act_icon = Icon:create():set_color(200, 200, 255, 0)
    act_icon.spatial = spatial:move(0, 200)
    act_icon.tween = Timer.tween(0.25, {
        [act_icon.spatial] = spatial,
        [act_icon.color] = {[4] = 255}
    }):group(self.__group.tween)
    self.actions[icon] = act_icon
    return self
end

function TurnBar:pop()
    if self.empty_actors:size() > 0 then return end
    local icon = self.filled_actors:tail()
    if not icon then return end
    self.filled_actors = self.filled_actors:erase()
    self.leaving_actors[icon] = true
    local targets = self.targets[icon] or {}
    local action = self.actions[icon]
    local animation = {}
    function animation.animate(convoke, context)
        local dy = -100
        local tween_target =  {}
        for _, i in pairs({icon, action, unpack(targets)}) do
            tween_target[i.color] = {[4] = 0}
            tween_target[i.spatial] = i.spatial:move(0, dy)
        end

        convoke:wait(convoke:tween(0.35, tween_target))
        self.leaving_actors[icon] = nil
        self.actions[icon] = nil
        self.targets[icon] = nil
    end
    local anime = Animation.animate(animation, self.__group.anime)
    anime:run()
end

function TurnBar:update(dt)
    Animation.update(dt, self.__group.anime)
    Timer.update(dt, self.__group.tween)
end

function TurnBar:draw(x, y)
    local function draw_icon(icon)
        icon:draw(x, y)
        local action = self.actions[icon]
        if not action then return end
        action:draw(x, y)
        local targets = self.targets[icon]
        if not targets then return end
        for _, t in ipairs(targets) do
            t:draw(x,  y)
        end
    end
    for _, icon in ipairs(self.filled_actors) do
        draw_icon(icon)
    end
    for _, icon in ipairs(self.empty_actors) do
        draw_icon(icon)
    end
    for icon, _ in pairs(self.leaving_actors) do
        draw_icon(icon)
    end
end

return TurnBar
