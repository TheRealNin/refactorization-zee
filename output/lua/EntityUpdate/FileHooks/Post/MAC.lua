if Server then
    local oldOnCreate = MAC.OnCreate
    function MAC:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end