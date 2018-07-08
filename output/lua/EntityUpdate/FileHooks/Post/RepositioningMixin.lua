if kUseFixedUpdates then
    local old__initmixin = RepositioningMixin.__initmixin
    function RepositioningMixin:__initmixin()
        old__initmixin(self)
        
        -- TODO: Fix this hack
        self.GetTickTime = function() return 0 end
    end
end