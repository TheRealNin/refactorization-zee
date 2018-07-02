if Server then
    local oldOnCreate = Drifter.OnCreate
    function Drifter:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end