local game = require "game"

local friend_type = require "actor/fencer"
local target_type = require "actor/box"
lume = require "modules/lume"
local lurker = require "modules/lurker"

function love.load(arg)
    gfx.setBackgroundColor(0, 0, 0, 0)
    function reload_scene()
        love.load(arg)
    end

    log.info("Initializing battle nodes")
    game.setup.init_battle()

    -- Start by initializing all actors

    local typemap = {}
    for i = 1, 4 do
        local id = game.setup.actor.state(i, friend_type)
        typemap[id] = friend_type
    end

    for i = 1, 4 do
        local id = game.setup.actor.state(-i, target_type)
        typemap[id] = target_type
    end

    local ability = arg[1]
    if not ability then
        log.warn("No ability given")
        return
    end
    ability = ability:gsub('.lua', '')
    log.info("Executing %s", ability)

    local ability = reload(ability)

    local user = nodes.position:get(1)

    local target_candidates = ability.target.candidates(
        nodes.position.placements, user
    )
    local target = target_candidates:values():tail()
    log.info("picking target %s", target)
    if ability.test_setup then
        ability.test_setup(user, target)
    end

    game.setup.actor.visual(user, friend_type)

    target_all = type(target) == "string" and list(target) or target

    for _, id in pairs(target_candidates:values()) do
        if id ~= user then
            local t = typemap[id]
            game.setup.actor.visual(id, t)
        end
    end
    log.info("Visuals initialized")
    for _, s in pairs(visual.sprite) do
        s:set_animation("idle")
    end

    nodes.animation:add(ability.run, user, target)

    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end

    function lurker.postswap(f)
        reload_scene()
    end
end

local do_update = true

function love.update(dt)
    lurker:update()
    if do_update then
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
end

local function draw_pause(x, y, w, h)
    gfx.setColor(1, 1, 1)
    if do_update then
        gfx.polygon("fill", x, y, x + w, y + h * 0.5, x, y + h)
    else
        gfx.setLineWidth(10)
        local c = x + w * 0.5
        gfx.line(c - 12, y, c - 12, y + h)
        gfx.line(c + 12, y, c + 12, y + h)
    end
end

function love.draw()
    for id, s in pairs(visual.sprite) do
        local pos = nodes.position:get_world(id)
        s:draw(pos:unpack())
    end

    nodes.sfx:draw()
    nodes.charge:draw()
    --nodes.shield:draw()
    nodes.damage_number:draw()

    for id, ui in pairs(visual.ui) do
        local pos = nodes.position:get_world(id) - vec2(0, 225)
        ui:draw(pos:unpack())
    end
    draw_pause(25, 25, 50, 40)
end

nodes.root.keypressed:listen(function(key)
    if key == "tab" then
        reload_scene()
    elseif key == "space" then
        do_update = not do_update
    end
end)
