if Server then
    local oldOnCreate = Projectile.OnCreate
    function Projectile:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end