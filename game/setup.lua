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
            tile = dict{
                collision = dict{
                    x = dict{}, y = dict{}
                },
            },
            script = dict{} -- Control node
        }
    end

    local function actor_events()
        return dict{}
    end

    nodes.actor_state = process.create(state, actor_state, actor_events)
end

function setup.visual()
    visual = {
        sprite = {},
        ui = {},
        level = {}
    }
end

return setup
