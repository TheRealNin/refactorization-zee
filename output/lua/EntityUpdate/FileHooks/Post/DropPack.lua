if kUseFixedUpdates then
    -- TODO: Make drop packs use triggers
    function DropPack:GetTickTime()
        return 0 -- realtime
    end
end