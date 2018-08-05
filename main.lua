gfx = love.graphics
log   = require "modules.log"
--log.outfile = '/tmp/game.log'

Atlas = require "atlas"
Timer = require "modules.knife.timer"
Event = require "event"
List = require "list"
Dictionary = require "dictionary"
Spatial = require "spatial"
process = require "node"
thread = require "thread"
id_gen = require "id_gen"
vec2 = require "vec2"
math = require "math"


dict = Dictionary.create
list = List.create
event = Event.create
spatial = Spatial.create
--Sprite = require "animation/sprite"

function reload(p)
    package.loaded[p] = nil
    return require(p)
end

function math.cycle(value, min, max)
    if value < min then
        return math.cycle(value + max - min + 1, min, max)
    elseif value > max then
        return math.cycle(value - max + min - 1, min, max)
    else
        return value
    end
end

function math.remap(value, prev_min, prev_max, next_min, next_max)
    local x = (value  - prev_min) / (prev_max - prev_min)

    return x * (next_max - next_min) + next_min
end

function math.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

function istype(Type, object)
    if type(Type) == type(object) and type(Type) ~= "table" then
        return true
    elseif type(Type) == "table" and type(object) == "table" then
        return Type.__index == object.__index
    else
        return false
    end
end

function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t=List.create() ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function root_node(self)
    self.keypressed = Event.create()
    self.keyreleased = Event.create()
end

nodes = {}

function love.load(arg)
    arg = list(unpack(arg))
    gfx.setDefaultFilter("nearest", "nearest")
    nodes.root = process.create(root_node)

    local old_load = love.load
    local entry = arg[1] or "battle"
    log.info("Entering %s", entry)

    entry = entry:gsub('/', '')

    local entrymap = {
        battle = "designer/battle",
        sfx = "designer/sfx",
        ability = "designer/ability",
        level = "designer/level"
    }

    entry = entrymap[entry]
    if entry then
        require(entry)
    end
    if love.load ~= old_load then
        return love.load(arg:sub(2))
    end
end

local keyrepeaters = {}

local function keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
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
    nodes.root.keyreleased(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    keyreleased(key, scancode)
    local timer = keyrepeaters[key]
    keyrepeaters[key] = nil
    timer:remove()
end
