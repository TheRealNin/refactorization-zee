-- fixes rifle exploit

local oldGetIsPrimaryAttackAllowed = Rifle.GetIsPrimaryAttackAllowed
function Rifle:GetIsPrimaryAttackAllowed(player)
	local oldVal = oldGetIsPrimaryAttackAllowed(self, player)
	if oldVal then
		local firedRecently = (Shared.GetTime() - self.timeAttackEnded) > 0.1
		return firedRecently
	end
	return oldVal
end