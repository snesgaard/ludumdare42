function love.load(args)
    local level = arg:head()
    if level then
        local p = level:gsub('.lua', '')
        local t = reload(p)
        nodes.level = process.create(t)
    end
end

function love.update(dt)
    Timer.update(dt)
    for _, n in pairs(nodes) do
        n:update(dt)
    end

    for _, s in pairs(visual.sprite) do
        s:update(dt)
    end

    for _, u in pairs(visual.ui) do
        u:update(dt)
    end
end


function love.draw()
    for id, s in pairs(visual.sprite) do
        s:draw(0, 0)
    end

    nodes.level:draw()
    nodes.sfx:draw()
    nodes.charge:draw()
    nodes.damage_number:draw()
end
