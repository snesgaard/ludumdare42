local slider = {}

function slider:test()
    self:set_size(100)
    self:set_value(1.0)
end

function slider:create()
    self.color = dict{
        slider = dict{0.35, 0.35, 0.35},
        handle = dict{0.9, 0.9, 0.9}
    }
    self.size = {
        slider = vec2(4, 150),
        handle = vec2(4, 20)
    }
    self.pos = vec2(0, 0)
    self.value = {min = 0, max = 1, value = 0, ratio = 0}
end

function slider:get_spatial()
    return spatial.create(self.pos.x, self.pos.y, self.size.slider:unpack())
end

function slider:set_spatial(spatial)
    self.size.slider.x = spatial.w
    self.size.slider.y = spatial.h
    self.size.handle.x = spatial.w
    self.pos = vec2(spatial.x, spatial.y)
    return self
end

function slider:set_size(h)
    self.size.slider.y = h
    return self
end

function slider:set_lim(min, max)
    self.value.min = min
    self.value.max = max
    return self:set_value(self.value.value)
end

function slider:set_value(value)
    local min, max = self.value.min, self.value.max
    self.value.value = math.clamp(value, min, max)
    if max - min > 0 then
        self.value.ratio = (self.value.value - min) / (max - min)
    else
        self.value.ratio = 0
    end
    return self
end

function slider:set_ratio(t)
    local min, max = self.value.min, self.value.max
    t = math.clamp(t, 0, 1)
    self.value.ratio = t
    self.value.value = min * (1 - t) + max * t
    return self
end

function slider:__draw(x, y, w, h)
    x = (x or 0) + self.pos.x
    y = (y or 0) + self.pos.y
    w = w or self.size.slider.x
    h = h or self.size.slider.y
    local function draw_slider()
        gfx.setColor(unpack(self.color.slider))
        gfx.rectangle("fill", x, y, w, h)
    end
    local function draw_handle()
        local _w, _h = self.size.handle:unpack()
        local min = vec2(0, 0)
        local max = vec2(0, h - _h)
        local t = self.value.ratio
        local pos = min * (1 - t) + max * t + vec2(x, y)
        gfx.setColor(unpack(self.color.handle))
        gfx.rectangle("fill", pos.x, pos.y, _w, _h)
    end
    draw_slider()
    draw_handle()
end

return slider
