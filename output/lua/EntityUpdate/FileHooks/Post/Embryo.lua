
if kUseFixedUpdates then

    -- TODO: Figure out why updates and callbacks here are NOT working
    --
    --[[
    local oldOnInitialized = Embryo.OnInitialized
    function Embryo:OnInitialized()
        local oldfunc = Entity.AddTimedCallbackActual
        Entity.AddTimedCallbackActual = Entity.AddTimedCallbackActualActual
        oldOnInitialized(self)
        self:SetUpdates(false)
        self:SetUpdatesActual(true)
        Entity.AddTimedCallbackActual = oldfunc

    end
    ]]--
    if Server then
    
        function Embryo:GetTickTime()
            return 0.1 -- match the old callback...
        end
        
        local func = debug.getupvaluex(Embryo.OnInitialized, "UpdateGestation")
        
        local oldOnUpdate = Embryo.OnUpdate
        function Embryo:OnUpdate(deltaTime)
            oldOnUpdate(self, deltaTime)
            func(self)
        end
    end
end