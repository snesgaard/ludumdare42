local TileMap = {}
TileMap.__index = TileMap

local TileTypes = {
    Full = 1,
    LEDGE = 2,
}

function TileMap.create(size, tilesize)
    local this = {
        size = size,
        tilesize = tilesize,
        data = {},
        pos = vec2(0, 0)
    }
    return setmetatable(this, TileMap)
end

function TileMap.from_tiled(map, layer_name)
    local layer_map = {}
    for i, layer in ipairs(map.layers) do
        layer_map[layer.name] = layer
    end
    local layer = layer_map[layer_name]

    if not layer then
        log.warn("No layer named %s", layer_name)
        return
    end

    local tilesize = vec2(map.tilewidth, map.tileheight)
    local size = vec2(layer.width, layer.height)
    local phys_map = TileMap.create(size, tilesize)
    for x = 1, size.x do
        for y = 1, size.y do
            if layer.data[y][x] then
                phys_map:insert(x - 1, y - 1, TileTypes.LEDGE)
            end
        end
    end
    return phys_map
end

function TileMap:get_size()
    return self.size:unpack()
end

function TileMap:get_tilesize()
    return self.tilesize:unpack()
end

function TileMap:insert(x, y, type)
    type = type or TileTypes.Full
    self.data[x + y * self.size.x] = type
    return self
end

function TileMap:remove(x, y)
    self.data[x + y * self.size.x] = nil
    return self
end

function TileMap:move(box, v, callback_x, callback_y, ignore_ledge)
    local p = vec2(0, 0)
    local final_v = vec2(0, 0)
    if v.x < 0 then
        p.x, col_x = self:__neg_motion_x(box, v)
    else
        p.x, col_x = self:__pos_motion_x(box, v)
    end

    box = box:move(p.x - box.x, 0)

    if v.y < 0 then
        p.y, col_y = self:__neg_motion_y(box, v)
    else
        p.y, col_y = self:__pos_motion_y(box, v, ignore_ledge)
    end

    local box = box:move(0, p.y - box.y)

    if col_x and callback_x then
        callback_x(box)
    end
    if col_y and callback_y then
        callback_y(box)
    end

    return box
end

local function valid_tile(map, x, y)
    local t = map:index(x, y)
    if not t then
        return false
    else
        return t ~= TileTypes.LEDGE
    end
end

function TileMap:__pos_motion_x(box, v)
    local init_index = self:__pos2index(
        box:corner("left", "top"):floor()
    )
    init_index = vec2(
        math.max(0, init_index.x), math.max(0, init_index.y)
    )
    local stop_index = self:__pos2index(
        box:move(v.x, 0):corner("right", "bottom"):floor()
    )
    stop_index = vec2(
        math.min(self.size.x - 1, stop_index.x),
        math.min(self.size.y - 1, stop_index.y)
    )


    for x = init_index.x, stop_index.x do
        for y = init_index.y, stop_index.y do
            if valid_tile(self, x, y) then
                return self:__index2pos(vec2(x, y)).x - box.w - 1e-5, true
            end
        end
    end
    return box.x + v.x, false
end

function TileMap:__neg_motion_x(box, v)
    local init_index = self:__pos2index(
        box:corner("right", "top"):floor()
    )
    init_index = vec2(
        math.min(self.size.x - 1, init_index.x), math.max(0, init_index.y)
    )
    local stop_index = self:__pos2index(
        box:move(v.x, 0):corner("left", "bottom"):floor()
    )
    stop_index = vec2(
        math.max(0, stop_index.x),
        math.min(self.size.y - 1, stop_index.y)
    )

    for x = init_index.x, stop_index.x, -1 do
        for y = init_index.y, stop_index.y do

            if valid_tile(self, x, y) then
                -- Add one as we hit the right side, effectively
                -- the left side of the next tile
                return self:__index2pos(vec2(x + 1, y)).x + 1e-5, true
            end
        end
    end

    return box.x + v.x, false
end

function TileMap:__pos_motion_y(box, v, ignore_ledge)
    local init_index = self
        :__pos2index(box:corner("left", "bottom"):floor())
        :max(0)
    local stop_index = self:__pos2index(
        box:move(0, v.y):corner("right", "bottom"):floor()
    )
        :min(self.size - 1)

    local function collision(x, y, box)
        local t = self:index(x, y)

        if not t then
            return false
        end

        if t == TileTypes.FULL then
            return true
        end

        print(ignore_ledge)

        if t == TileTypes.LEDGE and not ignore_ledge then
            local world = self:__index2pos(vec2(x, y))
            return world.y > box.y + box.h
        end
    end

    for y = init_index.y, stop_index.y do
        for x = init_index.x, stop_index.x do
            if collision(x, y, box) then
                local y = self:__index2pos(vec2(x, y)).y
                return y - box.h - 1e-5, true
            end
        end
    end
    return box.y + v.y, false
end

function TileMap:__neg_motion_y(box, v)
    local init_index = self
        :__pos2index(box:corner("left", "bottom"):floor())
    init_index = vec2(
        math.max(0, init_index.x), math.min(self.size.y - 1, init_index.y)
    )
    local stop_index = self:__pos2index(
        box:move(0, v.y):corner("right", "top"):floor()
    )
    stop_index = vec2(
        math.min(self.size.x - 1, stop_index.x), math.max(0, stop_index.y)
    )

    for y = init_index.y, stop_index.y, -1 do
        for x = init_index.x, stop_index.x do
            if valid_tile(self, x, y) then
                -- Add one as we hit the right side, effectively
                -- the left side of the next tile
                return self:__index2pos(vec2(x, y + 1)).y + 1e-5, true
            end
        end
    end
    return box.y + v.y, false
end

function TileMap:index(x, y)
    return self.data[x + y * self.size.x]
end

function TileMap:__pos2index(pos, dim)
    local index = (pos - self.pos) / self.tilesize
    return index:floor()
end

function TileMap:__index2pos(index)
    return index * self.tilesize + self.pos
end

function TileMap:draw(_x, _y)
    _x = _x or 0
    _y = _y or 0
    local w, h = self.tilesize:unpack()

    local function draw(x, y)
        x = _x + self.pos.x + x * w
        y = _y + self.pos.y + y * h
        gfx.rectangle("fill", x, y, w, h)
    end

    for x = 0, self.size.x - 1 do
        for y = 0, self.size.y - 1 do
            if self:index(x, y) then
                draw(x, y)
            end
        end
    end
end

return TileMap
