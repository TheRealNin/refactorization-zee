if Server then
    local oldOnCreate = Babbler.OnCreate
    function Babbler:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end