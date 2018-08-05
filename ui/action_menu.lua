local menu = require "ui/menu"
local textbox = require "ui/labelbox"
local frame = require "ui/frame"
local spatial = require "spatial"

local action_menu = {}

function action_menu:test()
    local items = list(
        menu.item("Foo", nil),
        menu.item("Bar", nil),
        menu.item("Boi", nil),
        menu.item("shizzle", nil),
        menu.item("fizzle", nil),
        menu.item("nizzle", nil),
        menu.item("bizzle", nil)
    )
    self.ui.menu
        :set_window_size(4)
        :set_items(items)
        :set_selected(1)
        .enable()

    --self.ui.menu.enable()

    self:restructure()
end

local function create_help_box(self)
    local box = self:child(textbox)
        :set_text("Deal 1 damage.")
        :set_width(300, 300)
    return box
end

function action_menu:create()
    self.ui = {
        menu = self:child(menu),
        helpbox = create_help_box(self)
    }

    self.ui.menu.on_change:listen(function(_, name, value)
        self:set_help(name, value)
    end)

    self.pos = vec2(0, 0)
    self:restructure()
end

function action_menu:set_help(name, value)
    if not item then
        local s = string.format("No help for %s.", name)
        self.ui.helpbox:set_text(s)
    else
        self.ui.helpbox:set_text(value.help_text())
    end
end

function action_menu:set_actions(action_list)

end

function action_menu:restructure()
    local base = self.ui.menu:get_spatial()

     local next = self.ui.helpbox
        :set_width(base.w)
        :get_spatial()
        :xalign(base, "center", "center")
        :yalign(base, "top", "bottom")
        :move(0, -2)
        :commit(self.ui.helpbox)

    return self
end

function action_menu:draw(x, y)
    self:restructure()
    self.ui.helpbox:draw(x, y)
    self.ui.menu:draw(x, y)
end

return action_menu
