
--[[
local oldOnUpdate = RepositioningMixin.OnUpdate
function RepositioningMixin:OnUpdate(deltaTime)
    oldOnUpdate(self, deltaTime)
    if self:GetIsRepositioning() then
        self:SetFastUpdates(true)
    else
        self:SetFastUpdates(false)
        self:SetUpdates(true)
    end
end
]]--