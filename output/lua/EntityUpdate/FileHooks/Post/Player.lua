
-- disabling real updates causes some really funky animation issues, specifically footstep sounds
function Player:UsesRealUpdates()
    return true
end

function Player:GetTickTime()
    return 0 -- realtime
end