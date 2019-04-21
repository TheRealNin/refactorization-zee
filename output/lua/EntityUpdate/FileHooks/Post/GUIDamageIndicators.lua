
-- fix a bug in vanilla (when not running ns2 community fixes)
if GUIDamageIndicators.kMinIndicatorSize == 0.25 then

	local oldPlayerUI_GetDamageIndicators = PlayerUI_GetDamageIndicators
	function PlayerUI_GetDamageIndicators()
		local oldVals = oldPlayerUI_GetDamageIndicators()
		
		for i = 1, #oldVals, 2 do
		
			-- TODO: Figure out exactly why vanilla only has the value 0.0-0.9 instead of 0.0-1.0 as per doc
			oldVals[i] = oldVals[i] * 0.9
			
		end
		
		return oldVals
	end
end
