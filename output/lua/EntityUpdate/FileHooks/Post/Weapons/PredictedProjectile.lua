if Server then
    local oldOnCreate = PredictedProjectile.OnCreate
    function PredictedProjectile:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end