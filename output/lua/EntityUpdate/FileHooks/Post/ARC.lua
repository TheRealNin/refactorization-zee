if Server then
    local oldOnCreate = ARC.OnCreate
    function ARC:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end