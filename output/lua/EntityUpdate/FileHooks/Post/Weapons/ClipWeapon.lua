if Server then
    local oldOnCreate = ClipWeapon.OnCreate
    function ClipWeapon:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end