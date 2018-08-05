local function character_thread(handle, id)
    local on_action = handle.on_action[id]
    local action = handle:wait(on_action)

    local context = {queue = list(action)}

    function callback(action)
        context.queue = context.queue:insert(action)
    end

    local listen = on_action:listen(callback)

    while context.queue:head() do
        local action = context.queue:head()
        context.queue = context.queue:body()
        action(handle, id)
    end

    listen:remove()
    return character_thread(handle, id)
end

local actions = {}

function actions.death(handle, id)
    local sprite = visual.sprite[id]
    local ui = visual.ui[id]
    local tween = Timer.tween(
        0.25,
        {
            [sprite.color] = {1, 0.2, 0.1, 1}
        }
    )
    handle:wait(tween)
    local tween = Timer.tween(
        0.25,
        {
            [sprite.color] = {0, 0, 0, 0}
        }
    )
    handle:wait(tween)
    ui:hide()
end

local monitor = {}
monitor.__index = monitor

function monitor:create()
    self.threads = dict()
    self.on_action = dict()

    nodes.game:monitor_stat("health/current", self:hp_callback())
end

function monitor:submit(id, action)
    self.on_action[id] = self.on_action[id] or event()
    self.threads[id] = self.threads[id] or self:fork(character_thread, id)

    local a = self.on_action[id]
    a(action)
    return self
end

function monitor:death(id)
    return self:submit(id, actions.death)
end

function monitor:hp_callback()
    return function(id, value)
        if value > 0 then return end

        self:death(id)
    end
end


return monitor
