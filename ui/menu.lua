local frame = require "ui/frame"
local label = require "ui/label"
local fonts = require "ui/fonts"
local button = require "ui/button"
local slider = require "ui/slider"
local spatial = require "spatial"

local window = {}
window.__index = window

function window.create(size, pos, max)
    local this = {
        size = size or 0,
        pos = pos or 1,
        max = max or 0
    }
    return setmetatable(this, window)
end

function window:__get_limits()
    return 1, self.max - self.size + 1
end

function window:get_range()
    local min = math.clamp(self.pos, 1, self.max)
    local max = math.clamp(self.pos + self.size - 1, 1, self.max)
    return min, max
end

function window:move(dx)
    dx = dx or 0
    self.pos = math.clamp(
        self.pos + dx, self:__get_limits()
    )
    return self
end

function window:set_size(size)
    self.size = size
    return self:move()
end

function window:set_max(max)
    self.max = max
    return self:move()
end

function window:set_pos(pos)
    local dx = pos - self.pos
    return self:move(dx)
end

function window:adjust(select)
    if not select then return self end

    local min, max = self:get_range()
    if select < min then
        return self:move(select - min)
    elseif max < select then
        return self:move(select - max)
    else
        return self
    end
end

local menu = {}

function menu:test()
    local items = list(
        self.item("Foo", 11),
        self.item("Bar", 11),
        self.item("Boi", 11),
        self.item("shizzle", 11),
        self.item("fizzle", 11)
    )
    self:set_window_size(3)
    self:set_items(items)

    for i = 1, #items do
        self:set_selected(i)
        self:wait(0.25)
    end
    for i = #items, 1, -1 do
        self:set_selected(i)
        self:wait(0.25)
    end

    self.enable()
end

function menu:create()
    self.window = window.create()
    self.items = list()
    self.ui = {
        frame = frame.create()
            :set_color(0.55, 0.55, 0.55)
        ,
        items = list(),
        slider = self:child(slider)
    }
    self.size = {
        item = vec2(200, 30)
    }
    self.pos = vec2(0, 0)
    self.margin = {
        inner = 5,
        outer = 10
    }
    self:set_selected(nil)

    self.enable = event()
    self.disable = event()

    self.on_select = event()
    self.on_change = event()
    self.on_abort = event()

    self:restructure()
    self:fork(self.control)
end

function menu:control()
    local function parse_key(key)
        if key == "up" then
            self:move_selected(-1)
        elseif key == "down" then
            self:move_selected(1)
        elseif key == "space" then
            self.on_select(self:get_selected_item())
            return true
        elseif key == "backspace" then
            self.on_abort()
            return true
        end
    end

    local function active()
        local event = self:wait(self.disable, nodes.root.keypressed)
        if event.event == self.disable then
            return
        else
            if not parse_key(unpack(event)) then
                return active()
            else
                return
            end
        end
    end

    while true do
        self:wait(self.enable)
        active()
    end
end

function menu:draw(x, y)
    x = (x or 0) + self.pos.x
    y = (y or 0) + self.pos.y

    self.ui.frame:draw(x, y)

    local function draw_items()
        local start, stop = self.window:get_range()
        local base = self.ui.items[start]
        if not base then
            return
        end
        base = base:get_spatial()
        for i = start, stop do
            local ui = self.ui.items[i]
            ui:draw(x - base.x, y - base.y)
        end
    end

    draw_items()

    if not self:all_visible() then
        self.ui.slider:draw(x, y)
    end
end

function menu:set_window_size(size)
    self.window:set_size(size)
    self:restructure()
    self:set_selected(self.selected)
    self:__update_slider_limit()
    self:__update_slider()
    return self
end

function menu:__update_slider()
    self.ui.slider:set_value(self.window.pos)
    return self
end

function menu:__update_slider_limit()
    self.ui.slider:set_lim(self.window:__get_limits())
    return self
end

function menu.item(name, value)
    return dict{name=name, value=value}
end

function menu:all_visible()
    return self.window.size >= self.items:size()
end

function menu:move_selected(ds)
    local s = self.selected
    if not s then
        return s
    else
        return self:set_selected(
            math.cycle(s + ds, 1, self.items:size())
        )
    end
end

function menu:get_selected_item()
    if self.selected then
        local s = self.selected
        return s, self.items[s].name, self.items[s].value
    end
end

function menu:set_selected(s)
    if s == self.selected then
        return self
    end
    if s then
        s = math.clamp(s, 1, self.ui.items:size())
    end
    if self.selected then
        local ui = self.ui.items[self.selected]
        ui:set_state(ui.normal)
    end
    if s then
        local ui = self.ui.items[s]
        ui:set_state(ui.selected)
    end

    self.window:adjust(s)

    self.selected = s

    self.on_change(self:get_selected_item())
    self:__update_slider()
    return self
end

function menu:restructure()
    local structure = dict{
        items = list()
    }

    local function get_spatial(node)
        if node then
            return node
        else
            return spatial.create(
                0, 0 - self.margin.inner, 0, 0
            )
        end
    end

    for i, n in ipairs(self.ui.items) do
        local prev = get_spatial(structure.items[i - 1])
        structure.items[i] = n:get_spatial()
            :xalign(prev, "left", "left")
            :yalign(prev, "top", "bottom")
            :move(0, self.margin.inner)
            :commit(n)
    end

    local function get_item_border()
        if self:all_visible() then
            return structure.items
        else
            return structure.items:sub(1, self.window.size)
        end
    end

    local item_border = spatial.join(get_item_border():unpack())

    local slider = item_border
        :compile()
        :set_size(4)
        :xalign(item_border, "left", "right")
        :yalign(item_border, "top", "top")
        :move(self.margin.inner, 0)
        :commit(self.ui.slider)

    local function get_frame_base()
        if self:all_visible() then
            return spatial.join(item_border)
        else
            return spatial.join(item_border, slider)
        end
    end

    structure.frame = get_frame_base()
        :compile()
        :expand(self.margin.outer, self.margin.outer)
        :commit(self.ui.frame)

    self.structure = structure
    return self
end

function menu:set_spatial(spatial)
    self.pos = vec2(spatial.x, spatial.y)
    return self
end

function menu:get_spatial()
    return self.structure.frame
end

function menu:set_items(items)
    local function ui_item(item)
        local name = item.name
        return self:child(button)
            :set_text(name)
            :set_spatial(spatial.create(0, 0, self.size.item:unpack()))
    end

    self.items = items
    for _, n in pairs(self.ui.items) do n:destroy() end
    self.ui.items = items:map(ui_item)
    self:restructure()
    self:set_selected(self.selected)
    self.window:set_max(#self.ui.items)
    self:__update_slider_limit()
    self:__update_slider()
    return self
end

return menu
