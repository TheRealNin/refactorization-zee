if kUseFixedUpdates then
    local oldOnUpdate = Shade.OnUpdate
    function Shade:OnUpdate(deltaTime)
        oldOnUpdate(self, deltaTime)
        
        local currentOrder = self:GetCurrentOrder()
        if GetIsUnitActive(self) and currentOrder and currentOrder:GetType() == kTechId.Move then
            self:SetFastUpdates(true)
        else
            self:SetUpdates(true)
        end
    end
end