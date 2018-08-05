local Frame = require "ui/frame"
local Label = require "ui/label"
local Fonts = require "ui/fonts"
local Spatial = require "spatial"


local Item = {}
Item.__index = Item

Item.selected = {}
Item.normal = {}

function Item:create(text)
    self.frame = Frame.create():set_color(1, 1, 1)
    self.label = Label.create():set_text(text):set_font(Fonts(14))
end


function Item:draw(...)
    self.frame:draw(...)
    gfx.setColor(0, 0, 0)
    self.label:draw(...)
end


function Item:set_spatial(spatial)
    self.frame:set_spatial(spatial)
    self.label:set_spatial(spatial)
    self.spatial = Spatial.create(spatial:unpack())
    return self
end


function Item.selected.enter(self)
    self.frame.color = {1, 1, 1}
    self.frame:set_spatial(self.spatial:copy())
    if not self.animation then
         self.animation = self:fork(self.selected.animate)
    end
end

function Item.selected.animate(self)
    local spatial = Spatial.create(self.spatial:unpack())
    local tween = Timer.tween(0.1, {
        [self.frame.spatial] = spatial:expand(5, 5),
        [self.frame.color] = {1, 1, 0}
    })
    self:wait(tween)
    tween = Timer.tween(0.1, {
        [self.frame.spatial] = spatial,
        [self.frame.color] = {1, 1, 0.45}
    })
    self:wait(tween)
    while true do
        tween = Timer.tween(0.5, {[self.frame.color] = {1, 1, 0.2}})
        self:wait(tween)
        tween = Timer.tween(0.5, {[self.frame.color] = {1, 1, 0.45}})
        self:wait(tween)
        self:wait(0.5)
    end
end


function Item.normal.enter(self)
    if self.animation then
        self:join{self.animation}
        self.animation = nil
    end

    self.frame.color = {1, 1, 1}
    self.frame:set_spatial(self.spatial:copy())
end


local Menu = {}
Menu.__index = Menu


function Menu:create(items)
    self.on_select = Event.create()
    self.on_abort = Event.create()
    self.on_change = Event.create()

    self.frame = Frame.create():set_color(0.55, 0.55, 0.55)
    local frame_spatial, item_spatials = self.structure(items)
    self.frame:set_spatial(frame_spatial)

    self.items = items
    local function __make_item_node(item)
        return process.create(Item, item.name)
    end
    self.item_nodes = items:map(__make_item_node)

    for index, node in pairs(self.item_nodes) do
        node:set_spatial(item_spatials[index]):set_state(node.normal)
    end

    self.active = 1
    self.item_nodes[1]:set_state(Item.selected)

    self.alive = true

    self:fork(Menu.controls)
end


function Menu:revive()
    if not self.alive then
        self.alive = true
        self:fork(Menu.controls)
    end
end


function Menu:kill()
    self.alive = false
    self.contol_co = nil
end

function Menu.controls(self)
    local key = self:wait(nodes.root.keypressed)

    local prev_active = self.active

    if key == "up" then
        self.active = self.active - 1
        if self.active < 1 then
            self.active = #self.items
        end
    elseif key == "down" then
        self.active = self.active + 1
        if self.active > #self.items then
            self.active = 1
        end
    elseif key == "space" then
        self.on_select(self.active, self.items[self.active])
    elseif key == "backspace" then
        self.on_abort(self.active, self.items[self.active])
    end

    if prev_active ~= self.active then
        self.item_nodes[prev_active]:set_state(Item.normal)
        self.item_nodes[self.active]:set_state(Item.selected)
        self.on_change(self:get_active())
    end

    if self.alive then
        return Menu.controls(self)
    end
end

function Menu:monitor_active(callback)
    callback(self:get_active())
    return self.on_change:listen(callback)
end

function Menu:get_active()
    return self.active, self.items[self.active].value
end

function Menu.structure(items)
    local base_spatial = Spatial.create(0, 0, 150, 30)
    local inter_margin = 5
    local outer_margin = 9

    local item_spatials = List.create()

    for i, item in ipairs(items) do
        item_spatials[i] = base_spatial
        base_spatial = base_spatial:move(0, inter_margin, "left", "bottom")
    end

    local frame_spatial = Spatial.border(unpack(item_spatials))
        :expand(outer_margin, outer_margin)

    return frame_spatial, item_spatials
end


function Menu:draw(...)
    self.frame:draw(...)

    for i, node in pairs(self.item_nodes) do
        node:draw(...)
    end
end

function Menu:get_spatial()
    return self.frame:get_spatial()
end

function Menu:__update(dt)
    for i, node in pairs(self.item_nodes) do
        node:update(dt)
    end
end

return {
    Item = function(name, value)
        return Dictionary.create{name=name, value=value}
    end,
    Menu = Menu
}
