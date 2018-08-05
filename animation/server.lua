local server = {}
server.__index = server

function server.create(self)
    self.queue = List.create()
    self.args = List.create()
    self.__wake = Event.create()
    self.on_done = Event.create()
    self.on_release = Event.create()

    self:fork(self.process)
end

function server:process()
    if self.queue:size() == 0 then
        self:wait(self.__wake)
    end

    local f = self.queue:head()
    self.queue = self.queue:body()
    local args = self.args:head()
    self.args = self.args:body()

    function self.release()
        self.on_done(f, unpack(args))
    end

    f(self, unpack(args))

    self:release()

    return self:process()
end

function server:add(f, ...)
    self.queue[#self.queue + 1] = f
    self.args[#self.args + 1] = {...}
    self.__wake()
end

return server
