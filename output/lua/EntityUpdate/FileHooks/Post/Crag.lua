if kUseFixedUpdates then
    local oldOnUpdate = Crag.OnUpdate
    function Crag:OnUpdate(deltaTime)
        oldOnUpdate(self, deltaTime)
        
        local currentOrder = self:GetCurrentOrder()
        if GetIsUnitActive(self) and currentOrder and currentOrder:GetType() == kTechId.Move then
            self:SetFastUpdates(true)
        else
            self:SetUpdates(true)
        end
    end
end