
kUseFixedUpdates = true

-- {id, interval, last_update}
local updaters = {}
local updaters_to_add = {}
local delete_updaters = {}

-- {id, callback, interval, early, last_update}
local callbacks = {}
local callbacks_to_add = {}
local delete_callbacks = {}

local kTickTime = 1.00

-- this is to make the game feel "smooth" on the client. Could be increased a little.
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
    for index, updater in ipairs(updaters) do
        if updater.id == id and not updater.deleted then
            updater.deleted = true
            table.insertunique(delete_updaters, index)
        end
    end
end

local function AddUpdater(id, interval)
    DeleteUpdater(id) -- there can be only one
    table.insert(updaters_to_add, {id=id, interval=interval, last_update=nil})
end

function Entity:AddTimedCallbackActual(callback, interval, early)
    table.insert(callbacks_to_add, {id=self:GetId(), callback=callback, interval=interval, early=early, last_update=Shared.GetTime()})
end

local function DeleteCallbacks(id)
    for index, callback in ipairs(callbacks) do
        if callback.id == id and not callback.deleted then
            callback.deleted = true
            table.insertunique(delete_callbacks, index)
        end
    end
end

function Entity:GetTickTime()
    return kTickTime
end
    
local oldOnInitialized = Entity.OnInitialized
function Entity:OnInitialized()
    oldOnInitialized(self)
    
    -- these are needed by animations and stuff, so don't disable them if we actually need them! 
    -- (no API to re-enable physics callbacks...)
    if HasMixin(self, "BaseModel") or HasMixin(self, "Controller") or HasMixin(self, "Live") then
    
    else
        self:DisableOnUpdatePhysics()
        self:DisableOnFinishPhysics()
    end
end
local oldOnDestroy = Entity.OnDestroy
function Entity:OnDestroy()
    
    DeleteUpdater(self:GetId())
    DeleteCallbacks(self:GetId())
    oldOnDestroy(self)
end

function Entity:SetFastUpdates(updates)
    self:SetUpdates(updates, 0.0)
end

function Entity:SetUpdates(updates, interval)
    --self:SetUpdatesActual(false)
    
    -- literally nothing uses OnPreUpdate so it's safe to disable it
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
    if ent then
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
        local return_val = callback.callback(ent, myDelta)
        if type(return_val) == "number" then
            callback.interval = return_val
        end
        return return_val
    end
    return false
end

local function CleanupAll()
    -- cleanup all callbacks and updates
    for i=#delete_updaters,1,-1 do
        DeleteUpdater(delete_updaters[i])
    end
    delete_updaters = {}
    
    table.sort(delete_callbacks)
    for i=#delete_callbacks,1,-1 do
        table.remove(callbacks, delete_callbacks[i])
    end
    delete_callbacks ={}
end

 -- add all callbacks and updaters waiting
local function AddWaiting()
    
    for i=#updaters_to_add,1,-1 do
        table.insert(updaters, updaters_to_add[i])
    end
    updaters_to_add = {}
    
    for i=#callbacks_to_add,1,-1 do
        table.insert(callbacks, callbacks_to_add[i])
    end
    callbacks_to_add = {}
    
end

local function EntityOnUpdate(deltaTime)

    local time = Shared.GetTime()
    
    CleanupAll()
    
    AddWaiting()
    
    
    -- early callbacks
    for index, callback in ipairs(callbacks) do
        if not callback.deleted and callback.early and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                table.insertunique(delete_callbacks, index)
            end
        end
    end
    
    -- OnUpdates
    for index, updater in ipairs(updaters) do
        if not updater.deleted and (not updater.last_update or updater.last_update + updater.interval <= time) then
            if not UpdateUpdater(updater, time) then
                --Log("We can only reach here if an entity no longer exists...")
                table.insertunique(delete_updaters, updater.id)
            end
        end
    end
    
    
    -- late callbacks
    for index, callback in ipairs(callbacks) do
        if not callback.deleted and not callback.early and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                table.insertunique(delete_callbacks, index)
            end
        end
    end
    
end

Event.Hook("UpdateServer", EntityOnUpdate)
Event.Hook("UpdateClient", EntityOnUpdate, "Client")
