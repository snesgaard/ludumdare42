local im = {}
im.__index = im

function im.create(draw, width, height)
    local this = {
        __draw = draw, width = width, height = height
    }
    return setmetatable(this, im)
end

function im:getWidth()
    return self.width
end

function im:getHeight()
    return self.height
end

function im:draw(x, y, r, sx, sy)
    self.__draw(x, y, self.width, self.height, r, sx, sy)
end

return im
