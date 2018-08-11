local state = require "game/state"

local setup = {}

function setup.state()
    local function actor_state()
        return dict{
            spatial = dict{},
            health = dict{
                current = dict{}, max = dict{}
            },
            speed = dict{},
            gravity = dict(),
            tile = dict{
                collision = dict{
                    x = dict{}, y = dict{}, tile = dict{}
                },
                ghost = dict(),
            },
            on_collision = dict(),
            script = dict{} -- Control node
        }
    end

    local function actor_events()
        return dict{}
    end

    nodes.actor_state = process.create(state, actor_state, actor_events)

    function get_stat(...)
        return nodes.actor_state:get_stat(...)
    end

    function set_stat(...)
        return nodes.actor_state:set_stat(...)
    end

    function monitor_stat(...)
        return nodes.actor_state:monitor_stat(...)
    end
end

function setup.visual()
    visual = {
        sprite = {},
        atlas = {},
        ui = {},
        level = {}
    }

    function load_atlas(path)
        if not visual.atlas[path] then
            local Atlas = require "atlas"
            visual.atlas[path] = Atlas.create(path)
        end
        return visual.atlas[path]
    end
end

return setup
