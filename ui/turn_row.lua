local marker = require "ui/turn_marker"

local row = {}

function row:test()
    local im = gfx.newImage("art/armor.png")
    self:set_selected(1)
    for i = 1, 8 do
        self:add(im, "Foo")
        --self:wait(0.5)
    end
    self:wait(self.on_queue_empty)
    self:wait(0.5)
    for i = 1, 4 do
        self:pop()
    end
    --self:add(im, "Foo")
end

function row:create()
    self.items = list()
    self.margin = 10
    self.offsets = list()
    self.on_action = event()
    self.on_queue_empty = event()
    self:fork(self.handle_animations)
end

function row:set_selected(s)
    self.selected = s
    return self
end

function row:add(im, name)
    local function action(self)
        local index = #self.items + 1
        self.items[index] = self:child(marker)
            :set_image(im)
            :set_text(name)
        self.offsets[index] = vec2(0, 1000)
        local tween = Timer.tween(
            0.1,
            {
                [self.offsets[index]] = vec2(0, 0)
            }
        )
        self:wait(tween)
    end

    self.on_action(action)
end

function row:pop()
    local function action()
        local index = #self.items
        local ui = self.items[index]
        local tween = Timer.tween(
            0.1,
            {
                [self.offsets[index]] = vec2(1000, 0)
            }
        )
        self:wait(tween)
        ui:destroy()
        self.items[index] = nil
        self.offsets[index] = nil
    end

    self.on_action(action)
end

function row:handle_animations(queue)
    queue = queue or list()

    if queue:size() == 0 then
        local action = self:wait(self.on_action)
        queue = queue:insert(action)
    end

    local context = {
        queue = queue
    }

    function callback(action)
        context.queue[#context.queue + 1] = action
    end

    local listener = self.on_action:listen(callback)

    while context.queue:head() do
        local action = context.queue:head()
        context.queue = context.queue:body()
        action(self)
    end

    self.on_queue_empty()
    listener:remove()
    return self:handle_animations(context.queue)
end

function row:structure()
    local prev = spatial(
        gfx.getWidth() - 50 + self.margin, gfx.getHeight() / 2 - 25, 0, 0
    )

    local struct = list()
    for i, marker in pairs(self.items) do
        local o = self.offsets[i] or 0
        struct[i] = marker:get_spatial()
            :xalign(prev, "right", "right")
            :yalign(prev, "bottom", "top")
            :move(o.x, -self.margin - o.y)
        prev = struct[i]
    end

    return struct
end


function row:draw(x, y)
    local struct = self:structure()

    for i = 1, self.items:size() do
        local item, s = self.items[i], struct[i]
        local x, y, w, h = s:unpack()
        if self.selected == i then
            gfx.setColor(1.0, 1.0, 0.1, 0.5)
            local s2 = s:compile():expand(self.margin, self.margin)
            local x, y, w, h = s2:unpack()
            gfx.rectangle("fill", x, y, w, h, 5)
        end
        item:draw(x, y)
    end
end

return row
