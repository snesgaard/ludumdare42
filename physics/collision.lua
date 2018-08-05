local collision = {}

function collision.miss_box(b1, b2)
    local function get_corners(b)
        return b:corner("left", "top"), b:corner("right", "bottom")
    end

    local tl1, br1 = get_corners(b1)
    local tl2, br2 = get_corners(b2)

    local miss_x = tl1.x > br2.x or tl2.x > br1.x
    local miss_y = tl1.y > br2.y or tl2.y > br1.y

    return miss_x, miss_y
end

function collision.detect(boxes)
    boxes = boxes:sort(function(b1, b2)
        return b1.x < b2.x
    end)

    local size = boxes:size()
    local collision_map = dict()

    local function handle_detection(b1, b2)
        local miss_x, miss_y = collision.miss_box(b1, b2)

        if not miss_x and not miss_y then
            local l1 = collision_map[b1] or list()
            collision_map[b1] = l1:insert(b2)
            local l2 = collision_map[b2] or list()
            collision_map[b2] = l2:insert(b1)
        end

        return miss_x
    end

    for i = 1, size do
        local b1 = boxes[i]
        for j = i + 1, size do
            local b2 = boxes[j]
            if handle_detection(b1, b2) then
                break
            end
        end
    end

    return collision_map
end

return collision
