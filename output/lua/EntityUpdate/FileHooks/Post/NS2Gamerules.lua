if Server then 
    -- this is just to be safe
    local oldOnCreate = NS2Gamerules.OnCreate
    function NS2Gamerules:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end