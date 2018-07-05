if kUseFixedUpdates then
    function Projectile:GetTickTime()
        return 0 -- realtime
    end
end

local oldAdjustInitial = Projectile.AdjustInitial
function Projectile:AdjustInitial(setup)
    oldAdjustInitial(self, setup)
    self.lastOrigin = self:GetOrigin()
end