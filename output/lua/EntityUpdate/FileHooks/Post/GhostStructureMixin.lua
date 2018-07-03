
local old__initmixin = GhostStructureMixin.__initmixin
function GhostStructureMixin:__initmixin()
    old__initmixin(self)
    --self.physicsModel:SetCollisionEnabled(true)
end

function GhostStructureMixin:OnInitialized()
    local coords = self:GetCoords()
    local extents = self:GetExtents()
    extents = extents * 3.0
    coords.origin.y = coords.origin.y + extents.y
    self.triggerBody = Shared.CreatePhysicsBoxBody(false, extents, 0, coords)
    self.triggerBody:SetTriggerEnabled(true)
    self.triggerBody:SetCollisionEnabled(false)
    
    if self:GetMixinConstants().kPhysicsGroup then
        --Print("set trigger physics group to %s", EnumToString(PhysicsGroup, self:GetMixinConstants().kPhysicsGroup))
        self.triggerBody:SetGroup(self:GetMixinConstants().kPhysicsGroup)
    end
    
    if self:GetMixinConstants().kFilterMask then
        --Print("set trigger filter mask to %s", EnumToString(PhysicsMask, self:GetMixinConstants().kFilterMask))
        self.triggerBody:SetGroupFilterMask(self:GetMixinConstants().kFilterMask)
    end
    
    self.triggerBody:SetEntity(self)
    
end
function GhostStructureMixin:OnDestroy()
    if self.triggerBody then
    
        Shared.DestroyCollisionObject(self.triggerBody)
        self.triggerBody = nil
        
    end
end

local function ClearGhostStructure(self)

    self.isGhostStructure = false
    self:TriggerEffects("ghoststructure_destroy")
    local cost = LookupTechData(self:GetTechId(), kTechDataCostKey, 0)
    self:GetTeam():AddTeamResources(cost)
    self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, cost, self:GetOrigin() + kWorldMessageResourceOffset, kResourceMessageRange)
    DestroyEntity(self)
end

debug.replaceupvalue( GhostStructureMixin.OnUpdate, "ClearGhostStructure", ClearGhostStructure, true)

function GhostStructureMixin:OnTriggerEntered(entity)

    if Server and self:GetIsGhostStructure() then
        if entity:GetIsAlive() and GetAreEnemies(self, entity) and 
            (
                entity:isa("Player") or
                entity:isa("Babbler") or
                entity:isa("Drifter") or
                entity:isa("Whip") or
                entity:isa("Crag") or
                entity:isa("Shift") or
                entity:isa("Shade") or
                entity:isa("Shade") or
                entity:isa("MAC") or
                entity:isa("ARC")
            ) then
        
            ClearGhostStructure(self)
        end
    end
end



if Server then
    local function CheckGhostState(self, doer)
    
        if self:GetIsGhostStructure() and GetAreFriends(self, doer) then
            self.isGhostStructure = false
            if self.triggerBody then
            
                Shared.DestroyCollisionObject(self.triggerBody)
                self.triggerBody = nil
                
            end
        end
        
    end
    
    -- If we start constructing, make us no longer a ghost
    function GhostStructureMixin:OnConstruct(builder, _)
        CheckGhostState(self, builder)
    end
end