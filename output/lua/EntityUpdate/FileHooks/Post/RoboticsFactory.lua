if kUseFixedUpdates then
    function RoboticsFactory:GetTickTime()
        return 0 -- realtime
    end
end