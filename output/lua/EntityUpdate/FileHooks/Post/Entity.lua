if Server then
    local slow_updaters = {}
    local fast_updaters = {}
    local accumulator = 0
    local tickTime = 0.1
    
    Entity.SetUpdatesActual = Entity.SetUpdates
    
    function Entity:SetFastUpdates(updates)
        self:SetUpdatesActual(false)
        if updates then
            self:SetUpdates(false)
            table.insertunique(fast_updaters, self:GetId())
        else
            table.removevalue(fast_updaters, self:GetId())
        end
    end
    
    function Entity:SetUpdates(updates)
        self:SetUpdatesActual(false)
        if updates and not table.contains(fast_updaters, self:GetId()) then
            table.insertunique(slow_updaters, self:GetId())
        else
            table.removevalue(slow_updaters, self:GetId())
        end
    end

    function EntityOnUpdateServer(deltaTime)
    
        for index, id in ipairs(fast_updaters) do
            local ent = Shared.GetEntity(id)
            if ent then
                ent:OnUpdate(deltaTime)
            else
                table.removevalue(fast_updaters, id)
            end
        end
        
        
        accumulator = accumulator + deltaTime
        while accumulator > tickTime do
            -- Log("Updating %s entities - fast: %s, slow: %s", tostring(#fast_updaters + #slow_updaters), #fast_updaters, #slow_updaters)
            accumulator = accumulator - tickTime
            for index, id in ipairs(slow_updaters) do
                local ent = Shared.GetEntity(id)
                if ent then
                    ent:OnUpdate(tickTime)
                else
                    table.removevalue(slow_updaters, id)
                end
            end
        end
        
        
    end
    
    Entity.slow_updaters = slow_updaters
    Entity.fast_updaters = fast_updaters
    
    Event.Hook("UpdateServer", EntityOnUpdateServer)
end