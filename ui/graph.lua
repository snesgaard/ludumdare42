local Node = {}
Node.__index = Node

function Node.__tostring(node)
    local typename = "Node"
    if node:type() and node:type().__tostring then
        typename = node:type().__tostring(node)
    end
    if node.__tag then
        return string.format("%s <%s>", typename, node.__tag)
    else
        return string.format("%s", typename)
    end
end

function Node.create(f, ...)
    local this = {}
    setmetatable(f, {__index = Node})
    f.__index = f
    this = setmetatable(this, f)
    f.create(this, ...)
    return this
end

function Node.init(state)
    local node = Node.create()
    node.__state = state
    return node
end

function Node:type()
    return self.__type or {}
end

function Node:__map(prev_state, ...)
    local map = self:type().map or function(s) return s end
    return map(self, prev_state, ...)
end

function Node:map(...)
    local prev_state = self.__prev and self.__prev:read() or {}

    return self:__map(prev_state)
end

function Node:info()
    if not self.__info then
        self.__state, self.__info = self:map()
    end
    return self.__info
end

function Node:read()
    if not self.__state then
        self.__state, self.__info = self:map()
    end
    return self.__state
end

function Node:node(Type, ...)
    local next = Node.create(Type, ...)
    next.__prev = self
    return next
end

function Node:clear()
    self.__state, self.__info = nil, nil
    return self
end

function Node:tag(tag)
    self.__tag = tag
    return self
end

function Node:find(tag)
    local function cmp(s)
        return s == tag
    end
    local f = type(name) == "function" and name or cmp
    local node = self
    while node and not f(node.__tag) do
        node = node.__prev
    end
    return node
end

function Node:link(dst)
    local node = self
    local graph = List.create()
    while node ~= dst and node do
        graph[#graph + 1] = node
        node = node.__prev
    end
    if not node == dst then
        return
    else
        return graph:insert(dst):reverse()
    end
end

function Node:compile()
    local state = self:read()
    return Node.create()
end

return Node
