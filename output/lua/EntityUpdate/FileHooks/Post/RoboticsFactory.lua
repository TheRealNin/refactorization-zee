if Server then
    local oldOnCreate = RoboticsFactory.OnCreate
    function RoboticsFactory:OnCreate()
        oldOnCreate(self)
        self:SetFastUpdates(true)
    end
end