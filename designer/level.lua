lume = require "modules/lume"
local lurker = require "modules/lurker"
local level_node = require "game/level"
local setup = require "game/setup"

function reload(p)
    package.loaded[p] = nil
    return require(p)
end

function love.load(args)
    setup.state()
    setup.visual()

    local level = args:head()
    if level then
        nodes.level = process.create(level_node, level)
    end

    function reload_scene()
        love.load(args)
    end

    function lurker.preswap(f)
        f = f:gsub('.lua', '')
        package.loaded[f] = nil
    end
    function lurker.postswap(f)
        reload_scene()
    end
end

function love.update(dt)
    lurker:update()
    Timer.update(dt)
    for _, n in pairs(nodes) do
        n:update(dt)
    end
end


function love.draw()
    nodes.level:draw(0, 0)
    for id, s in pairs(visual.sprite) do
        local pos = nodes.actor_state:get_stat("spatial", id) or spatial(0, 0)
        if type(s) == "table" then
            s:draw(pos.x, pos.y)
        elseif type(s) == "function" then
            s(id, pos.x, pos.y)
        end
    end
end
