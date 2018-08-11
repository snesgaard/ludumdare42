lume = require "modules/lume"
local lurker = require "modules/lurker"
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
        local level_node = require "game/level"
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

pause = false

nodes.root.keypressed:listen(function(key)
    if key == "tab" then
        pause = not pause
    end
end)

function love.update(dt)
    lurker:update()
    if not pause then
        Timer.update(dt)
        for _, n in pairs(nodes) do
            n:update(dt)
        end
    end
end


function love.draw()
    nodes.level:draw(0, 0)
end
