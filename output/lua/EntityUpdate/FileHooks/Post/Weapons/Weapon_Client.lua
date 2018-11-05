
local oldUpdateDropped = Weapon.UpdateDropped
function Weapon:UpdateDropped()
	oldUpdateDropped(self)
	if self:GetParent() and self.weaponWorldState then
		self.weaponWorldState = false
		EquipmentOutline_UpdateModel(self)
	end
end