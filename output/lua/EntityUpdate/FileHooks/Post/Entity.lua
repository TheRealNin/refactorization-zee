
kUseFixedUpdates = true

-- {id, interval, last_update}
local updaters = {}

-- {callback, interval, early}
local callbacks = {}

local kTickTime = 1.00

-- this is to make the game feel "smooth"
if Client then
    kTickTime = 1/5.0
end

Entity.SetUpdatesActual = Entity.SetUpdates
Entity.AddTimedCallbackActualActual = Entity.AddTimedCallbackActual


local function GetUpdater(id)
    for index, updater in ipairs(updaters) do
        if updater.id == id then
            return updater
        end
    end
    return nil
end

local function DeleteUpdater(id)
    local i = 1
    while i <= #updaters do
        if updaters[i].id == id then
            table.remove(updaters, i)
        else
            i = i + 1
        end
    end
end

local function AddUpdater(id, interval)
    DeleteUpdater(id)
    table.insert(updaters, {id=id, interval=interval, last_update=nil})
end

function Entity:AddTimedCallbackActual(callback, interval, early)
    table.insert(callbacks, {id=self:GetId(), callback=callback, interval=interval, early=early, last_update=Shared.GetTime()})
end

local function DeleteCallbacker(id)
    local i = 1
    while i <= #callbacks do
        if callbacks[i].id == id then
            table.remove(callbacks, i)
        else
            i = i + 1
        end
    end
end

function Entity:GetTickTime()
    return kTickTime
end
    
local oldOnDestroy = Entity.OnDestroy
function Entity:OnDestroy()
    DeleteUpdater(self:GetId())
    DeleteCallbacker(self:GetId())
    oldOnDestroy(self)
end

function Entity:SetFastUpdates(updates)
    self:SetUpdates(updates, 0.0)
end

function Entity:SetUpdates(updates, interval)
    self:SetUpdatesActual(false)
    self:DisableOnPreUpdate()
    if updates then
        if not interval then
            interval = self:GetTickTime() or kTickTime
        end
        AddUpdater(self:GetId(), interval)
    else
        DeleteUpdater(self:GetId())
    end
end

local function UpdateUpdater(updater, time)
    local ent = Shared.GetEntity(updater.id)
    if ent and not ent:GetIsDestroyed() then
        local myDelta = time - (updater.last_update or time)
        updater.last_update = time
        ent:OnUpdate(myDelta)
        return true
    end
    return false
end

local function UpdateCallback(callback, time)
    local ent = Shared.GetEntity(callback.id)
    if ent then
        local myDelta = time - (callback.last_update or time)
        callback.last_update = time
        return callback.callback(ent, myDelta)
    end
    return false
end

local function EntityOnUpdate(deltaTime)
    local time = Shared.GetTime()
    
    local delete_callbacks ={}
    
    -- early callbacks
    for index, callback in ipairs(callbacks) do
        if callback.early and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                table.insert(delete_callbacks, index)
            end
        end
    end
    
    -- OnUpdates
    local delete_updaters = {}
    for index, updater in ipairs(updaters) do
        if not updater.last_update or updater.last_update + updater.interval <= time then
            if not UpdateUpdater(updater, time) then
                table.insert(delete_updaters, index)
            end
        end
    end
    -- cleanup updaters
    for i=#delete_updaters,1,-1 do
        table.remove(updaters, delete_updaters[i])
    end
    
    -- late callbacks
    for index, callback in ipairs(callbacks) do
        if not callback.early and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                table.insert(delete_callbacks, index)
            end
        end
    end
    
    -- cleanup callbacks
    for i=#delete_callbacks,1,-1 do
        table.remove(callbacks, delete_callbacks[i])
    end
    
end

Event.Hook("UpdateServer", EntityOnUpdate)
Event.Hook("UpdateClient", EntityOnUpdate, "Client")

-- safety for client
if not Entity.SetFastUpdates then
    Entity.SetFastUpdates = Entity.SetUpdates
end