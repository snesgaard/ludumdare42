local VisualState = {}
VisualState.__index = VisualState

function VisualState.create()
    local visualstate = {
        ui = {
            numbers = DamageNumberServer.create()
        },
        spatial = Dictionary.create(),
        face = {},
        atlas = {},
        sprite = Dictionary.create(),
        icon = {
            color = {},
            bw = {},
        }
    }
    return setmetatable(visualstate, VisualState)
end

function VisualState:init(id, type_path)
    local function __do_load_type(state, id, type_path)
        local type_script = require(type_path)
        local init = type_script.init_visual
        init(state, id)
    end

    local status, msg = pcall(__do_load_type, self, id, type_path)

    if not status then
        log.warn(
            "Loading of <%s, %s> failed:  %s", id, type_path,
            msg
        )
    end
end

return VisualState
