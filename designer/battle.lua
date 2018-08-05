game = require "game"

function love.load(arg)
    gfx.setBackgroundColor(0, 0, 0, 0)
    game.setup.init_battle()
    nodes.holder = process.create()

    -- only pick the first scene
    local scene = arg:head()
    if scene then
        local p = scene:gsub('.lua', '')
        print("loading", p)
        local t = reload(p)
        nodes.holder:child(t)
        nodes.battle_planner:begin()
    end
end


function love.update(dt)
    Timer.update(dt)
    for _, n in pairs(nodes) do
        n:update(dt)
    end

    for _, s in pairs(visual.sprite) do
        s:update(dt)
    end

    for _, u in pairs(visual.ui) do
        u:update(dt)
    end
end

function love.draw()
    for id, s in pairs(visual.sprite) do
        local pos = nodes.position:get_world(id)
        s:draw(pos:unpack())
    end

    nodes.sfx:draw()
    nodes.charge:draw()
    nodes.damage_number:draw()

    for id, ui in pairs(visual.ui) do
        local pos = nodes.position:get_world(id) - vec2(0, 225)
        ui:draw(pos:unpack())
    end

    nodes.battle_planner:draw()
    nodes.round_planner:draw()
    nodes.turn:draw()
end

local keyrepeaters = {}

local function keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
    if key == "p" then
        for _, s in pairs(visual.sprite) do
            s:shake()
        end
    end
    nodes.root.keypressed(key, scancode, isrepeat)
end

function love.keypressed(key, scancode, isrepeat)
    local function callback()
        keypressed(key, scancode, isrepeat)
    end
    local interval = 0.35
    keyrepeaters[key] = Timer.every(interval, callback)
    callback()
end

local function keyreleased(key, scancode)

end

function love.keyreleased(key, scancode)
    keyreleased(key, scancode)
    local timer = keyrepeaters[key]
    keyrepeaters[key] = nil
    timer:remove()
end
