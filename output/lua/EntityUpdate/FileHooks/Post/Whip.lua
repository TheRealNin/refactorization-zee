if kUseFixedUpdates then
    function Whip:GetTickTime()
        return 0 -- realtime
    end
    
    local oldOnInitialized = Whip.OnInitialized
    function Whip:OnInitialized()
        oldOnInitialized(self)
        self:SetUpdates(false)
        self:SetUpdatesActual(true)
    end
end