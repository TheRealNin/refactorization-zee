
-- set to false when disabling the fixed updates hacks on all other entities
-- (convenience var - will be deleted later)
-- use like kUseFixedUpdates=Server to only enable on the server
kUseFixedUpdates = true

Log("Refactorization Zee loaded. Be prepared for a bumpy ride.")

-- {id, interval, last_update}
local updaters = {}
local updaters_to_add = {}

-- {id, callback, interval, early, last_update}
local callbacks = {}
local callbacks_early = {}
local callbacks_to_add = {}

local kTickTime = 1/4.0

-- this is to make the game feel "smooth" on the client. Could be increased a little.
if Client then
    kTickTime = 1/10.0
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

-- This function returns nil if the entry is planning to add or delete
local function GetUpdater(id)
    
    -- if an updater is waiting to be added, return that one
    for index, updater in ipairs(updaters_to_add) do
        if updater.id == id then
            return updater
        end
    end
    
    for index, updater in ipairs(updaters) do
        if updater.id == id and not updater.deleted then
            return updater
        end
    end
    return nil
end

-- actually only marks it to be deleted on the next sweep
local function DeleteUpdater(id)

    for index, updater in ipairs(updaters) do
        if updater.id == id then
            updater.deleted = true
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
        if callback.id == id then
            callback.deleted = true
        end
    end
    for index, callback in ipairs(callbacks_early) do
        if callback.id == id then
            callback.deleted = true
        end
    end
    
    
    for i=#callbacks_to_add,1,-1 do
        if callbacks_to_add[i].id == id then
            table.remove(callbacks_to_add, i)
        end
    end
end

local function AddUpdater(id, interval)
    local existing = GetUpdater(id)
    if existing then
        existing.interval = interval
    else
        DeleteUpdater(id)
        table.insert(updaters_to_add, {id=id, interval=interval, last_update=nil})
    end
end

function Entity:AddTimedCallbackActual(callback, interval, early)
	if not callback then
		-- Log("Info: callback not added due to null ref")
		return
	end
    table.insert(callbacks_to_add, {id=self:GetId(), callback=callback, interval=interval, early=early, last_update=Shared.GetTime()})
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

local function UpdateUpdater(updater, time, tickDelta)
    local ent = Shared.GetEntity(updater.id)
    if ent then
        local myDelta = time - (updater.last_update or Shared.GetPreviousTime())
		if updater.interval <= tickDelta and tickDelta ~= myDelta then
			--Log("deltaTime difference of %s", tickDelta - myDelta)
			myDelta = tickDelta
		end
		
        -- only actually update entities without parents....
		local hasParent
        if ent:GetParentId() == Entity.invalidId or not ent:GetParent() then
			hasParent = false
		else
			hasParent = true
        end
		
        if not updater.hasParent or not hasParent then
			ent:OnUpdate(myDelta)
		end
        
		updater.hasParent = hasParent
        updater.last_update = time
        
        return true
    end
    return false
end

local function UpdateCallback(callback, time)
    local ent = Shared.GetEntity(callback.id)
    if ent then
        local myDelta = time - (callback.last_update or Shared.GetPreviousTime())
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

    for i=#updaters,1,-1 do
        if updaters[i].deleted then
            table.remove(updaters, i)
        end
    end
    
    for i=#callbacks,1,-1 do
        if callbacks[i].deleted then
            table.remove(callbacks, i)
        end
    end
    
    for i=#callbacks_early,1,-1 do
        if callbacks_early[i].deleted then
            table.remove(callbacks_early, i)
        end
    end
    
end

 -- add all callbacks and updaters waiting
local function AddWaiting()
    
    for i, new_updater in ipairs(updaters_to_add) do
        table.insert(updaters, new_updater)
    end
    table.clear(updaters_to_add)
    
    for i, new_callback in ipairs(callbacks_to_add) do
        if new_callback.early then
            table.insert(callbacks_early, new_callback)
        else
            table.insert(callbacks, new_callback)
        end
    end
    table.clear(callbacks_to_add)
    
end

local function EntityOnUpdate(deltaTime)
    
    if Shared.GetIsRunningPrediction() or Predict then
        return
    end
    
    local time = Shared.GetTime()
    
    CleanupAll()
    AddWaiting()
    
    -- Log("Updaters: %s, callbacks: %s, early callbacks: %s", #updaters, #callbacks, #callbacks_early)
    
    -- early callbacks
    for index, callback in ipairs(callbacks_early) do
        if not callback.deleted and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                callback.deleted = true
            end
        end
    end
    
    -- OnUpdates
    for index, updater in ipairs(updaters) do
        if not updater.deleted and (not updater.last_update or updater.last_update + updater.interval <= time) then
            
            if not UpdateUpdater(updater, time, deltaTime) then
                -- not sure this should actually happen
                -- this usually happens when an entity moves out of relevancy without calling OnDestroy
                DeleteUpdater(updater.id)
            end
            
        end
    end
    
    
    -- late callbacks
    for index, callback in ipairs(callbacks) do
        if not callback.deleted and callback.last_update + callback.interval <= time then
            if not UpdateCallback(callback, time) then
                callback.deleted = true
            end
        end
    end
    
end

Event.Hook("UpdateServer", EntityOnUpdate)
Event.Hook("UpdateClient", EntityOnUpdate, "Client")

-- OnUpdateRender overload. Only client.
-- Might be better for people with bad CPUs?
--[[
local oldOnCreate = Entity.OnCreate
function Entity:OnCreate()
	oldOnCreate(self)
	self:DisableOnUpdateRender()
end

local last_render = Shared.GetTime()
local function EntityOnUpdateRender()
	local deltaTime = Shared.GetTime() - last_render
	last_render = Shared.GetTime()
	
	local ents = Shared.GetEntitiesWithClassname("Entity")
	for index, ent in ientitylist(ents) do
		if ent and ent.OnUpdateRender then
			ent:OnUpdateRender(deltaTime)
		end
	end
end
Event.Hook("UpdateRender", EntityOnUpdateRender)
]]--
