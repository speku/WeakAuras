local p = "player"
local minHealPercentage = 0.1
local relevantDmg = {
    SPELL_DAMAGE = 15,
    SPELL_PERIODIC_DAMAGE = 15,
    RANGE_DAMAGE = 12,
    SWING_DAMAGE = 12
    --ENVIRONMENTAL_DAMAGE = 15
}
local function extract(...)
    return select(relevantDmg[select(2,...)],...)
end
local f = CreateFrame("Frame","BDKHB")
function f:UpdateArtifactTraits()
    local u,e,a=UIParent,"ARTIFACT_UPDATE",C_ArtifactUI
    u:UnregisterEvent(e)
    SocketInventoryItem(16)
    local _,_,rank,_,bonusRank = a.GetPowerInfo(950)
    self.wf = 1 + (rank + bonusRank) * 0.05
    a.Clear()
    u:RegisterEvent(e)
end
function f:TalentsUpdated()
    self.goet = select(4, GetTalentInfo(6,2,1))
end
function f:StatsUpdated()
  self.m = GetMasteryEffect() / 100
  self.v = (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)) / 100 + 1
end
function f:Clean(error)
    local t = GetTime()
    for i = #self.dmgs,1,-1 do
        local dmg = self.dmgs[i]
        if dmg and t >= dmg[1] - (error and error or 0) then
            self.dmg = self.dmg - dmg[2]
            table.remove(self.dmgs, i)
        end
    end
end
function f:Init()
    self.clrUseTwo = {0,1,0,1}
    self.clrUseOne = {0,0.8,0,1}
    self.clr = {0,0.6,0,1}
    self.currentClr = self.clr
    self.dmgs = {}
    self.m = 0
    self.dmg = 0
    self.sinceLastUpdate = 0
    self.freq = 0.2
    self.ch = UnitHealth(p)
    self.mh = UnitHealthMax(p)
    self.ds = GetSpellInfo(49998)
    self.minHeal = self.mh * minHealPercentage
    self.pre = 0
    self.preShield = 0
    self.deathStrikeUsable = false
    self.absorbs = UnitGetTotalAbsorbs(p)
    -- self:UpdateArtifactTraits()
    -- self:TalentsUpdated()
    self:StatsUpdated()
end
function f:Predict()
    local ch = self.dmg * 0.2
    self.pre = (ch > self.minHeal and ch or self.minHeal) * self.v
    self.preShield = self.pre * self.m
    self.currentClr = self.ch + self.pre > self.mh and self.clr or self.clrUseTwo
end
function f:Health()
    self.mh = UnitHealthMax(p)
    self.ch = UnitHealth(p)
    self.minHeal = self.mh * minHealPercentage
end
f:SetScript("OnUpdate",function(s,elapsed)
        s.sinceLastUpdate = s.sinceLastUpdate + elapsed
        if s.sinceLastUpdate >= s.freq then
            s.sinceLastUpdate = 0
            s:Clean(s.freq/2)
            s:Predict()
        end
end)
local events = {
    "COMBAT_LOG_EVENT_UNFILTERED",
    -- "SPELLS_CHANGED",
    "UNIT_HEALTH_FREQUENT",
    -- "UNIT_AURA",
    "SPELL_UPDATE_CHARGES",
    -- "PLAYER_TALENT_UPDATE",
    "COMBAT_RATING_UPDATE",
    "UNIT_POWER_FREQUENT",
    "UNIT_ABSORB_AMOUNT_CHANGED"
}
for _,e in ipairs(events) do
    f:RegisterEvent(e)
end
f:SetScript("OnEvent", function(s,e,...)
    if e == "COMBAT_LOG_EVENT_UNFILTERED" then
        local id = UnitGUID(p)
        local se = select(2,...)
        if select(8,...) == id and relevantDmg[se] then
            local dmg = extract(...)
            s.dmg = s.dmg + dmg
            table.insert(s.dmgs, {GetTime()+5, dmg})
            s:Predict()
        end
    -- elseif e == "SPELLS_CHANGED" then
    --     s:UpdateArtifactTraits()
    -- elseif e == "SPELL_UPDATE_CHARGES" then
    --     s.charges = GetSpellCharges(s.frenzied)
    -- elseif e == "PLAYER_TALENT_UPDATE" then
    --     s:TalentsUpdated()
    elseif e == "COMBAT_RATING_UPDATE" then
        s:StatsUpdated()
    elseif e == "UNIT_ABSORB_AMOUNT_CHANGED" then
        s.absorbs = UnitGetTotalAbsorbs(p)
    else
        s:Clean()
        f:Health()
        s:Predict()
        s.deathStrikeUsable = IsUsableSpell(s.ds)
    end
end)
f:Init()
aura_env.f = f
