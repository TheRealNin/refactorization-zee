
-- set to false when disabling the fixed updates hacks on all other entities
-- (convenience var - will be deleted later)
-- use like kUseFixedUpdates=Server to only enable on the server
kUseFixedUpdates = true


-- {id, interval, last_update}
local updaters = {}
local updaters_to_add = {}
local delete_updaters = {}

-- {id, callback, interval, early, last_update}
local callbacks = {}
local callbacks_to_add = {}
local delete_callbacks = {}

local kTickTime = 1.00/10

-- this is to make the game feel "smooth" on the client. Could be increased a little.
if Client then
    kTickTime = 1/5.0
end

function Entity:GetTickTime()
    return kTickTime
end

-- set to true to bypass this update system
function Entity:UsesRealUpdates()
    return false
end
    

Entity.SetUpdatesActual = Entity.SetUpdates
Entity.AddTimedCallbackActualActual = Entity.AddTimedCallbackActual



-- actually only marks it to be deleted on the next sweep
local function DeleteUpdater(id)

    for index, updater in ipairs(updaters) do
        if updater.id == id and not updater.deleted then
            updater.deleted = true
            table.insertunique(delete_updaters, index)
        end
    end
    
    for i=#updaters_to_add,1,-1 do
        if updaters_to_add[i].id == id then
            table.remove(updaters_to_add, i)
        end
    end
    
end

local function DeleteCallbacks(id)
    for index, callback in ipairs(callbacks) do
        if callback.id == id and not callback.deleted then
            callback.deleted = true
            table.insertunique(delete_callbacks, index)
        end
    end
    
    for i=#callbacks_to_add,1,-1 do
        if callbacks_to_add[i].id == id then
            table.remove(callbacks_to_add, i)
        end
    end
end

local function AddUpdater(id, interval)
    DeleteUpdater(id)
    table.insert(updaters_to_add, {id=id, interval=interval, last_update=nil})
end

function Entity:AddTimedCallbackActual(callback, interval, early)
    table.insert(callbacks_to_add, {id=self:GetId(), callback=callback, interval=interval, early=early, last_update=Shared.GetTime()})
end

local oldOnInitialized = Entity.OnInitialized
function Entity:OnInitialized()
    oldOnInitialized(self)
    
    -- literally nothing uses OnPreUpdate so it's safe to disable it
    self:DisableOnPreUpdate()
    
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

local function trueFunc() return true end

function Entity:SetUpdates(updates, interval)

    if self:UsesRealUpdates() then
        self:SetUpdatesActual(updates)
        return
    end
    self:SetUpdatesActual(false)
    
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

-- cleanup all callbacks and updates
local function CleanupAll()
    table.sort(delete_updaters)
    for i=#delete_updaters,1,-1 do
        table.remove(updaters, delete_updaters[i])
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
    
    for i, new_updater in ipairs(updaters_to_add) do
        table.insert(updaters, new_updater)
    end
    updaters_to_add = {}
    
    for i, new_callback in ipairs(callbacks_to_add) do
        table.insert(callbacks, new_callback)
    end
    callbacks_to_add = {}
    
end

local function EntityOnUpdate(deltaTime)
    
    if Shared.GetIsRunningPrediction() then
        return
    end
    
    local time = Shared.GetTime()
    
    CleanupAll()
    AddWaiting()
    
    --Log("Updaters: %s, callbacks: %s", #updaters, #callbacks)
    
    -- early callbacks
    for index, callback in ipairs(callbacks) do
        if not callback.deleted and callback.early and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                callback.deleted = true
                table.insertunique(delete_callbacks, index)
            end
        end
    end
    
    -- OnUpdates
    for index, updater in ipairs(updaters) do
        if not updater.deleted and (not updater.last_update or updater.last_update + updater.interval <= time) then
            
            if not UpdateUpdater(updater, time) then
                DeleteUpdater(updater.id)
            end
            
        end
    end
    
    
    -- late callbacks
    for index, callback in ipairs(callbacks) do
        if not callback.deleted and not callback.early and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                callback.deleted = true
                table.insertunique(delete_callbacks, index)
            end
        end
    end
    
end

Event.Hook("UpdateServer", EntityOnUpdate)
Event.Hook("UpdateClient", EntityOnUpdate, "Client")
