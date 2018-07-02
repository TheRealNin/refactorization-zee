if Server then
    local oldOnCreate = CommandStation.OnCreate
    function CommandStation:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end