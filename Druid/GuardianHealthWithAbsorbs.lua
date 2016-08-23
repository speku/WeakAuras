local p = "player"
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
local f = CreateFrame("Frame","GDFRP")
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
    self.m = GetMasteryEffect() / 100 + 1
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
    self.mastery = GetSpellInfo(155783)
    self.frenzied = GetSpellInfo(22842)
    self.goe = GetSpellInfo(155578)
    self.nd = GetSpellInfo(211160)
    self.m = 1
    self.dmg = 0
    self.sinceLastUpdate = 0
    self.freq = 0.2
    self.hotRemaining = 0
    self.ch = UnitHealth(p)
    self.absorbs = UnitGetTotalAbsorbs(p) or 0
    self.mh = UnitHealthMax(p)
    self.minHeal = self.mh * 0.05
    self.pre = 0
    self.charges, self.maxCharges = GetSpellCharges(self.frenzied)
    self:UpdateArtifactTraits()
    self:TalentsUpdated()
    self:StatsUpdated()
end

function f:Predict()
    local ch = self.dmg * 0.5
    local nd
    do
        local b,_,_,c = UnitBuff(p,self.nd)
        nd = b and 1 + c * (1/3) or 1
    end
    local b = UnitBuff(p,self.goe)
    local m = b and 1.2 or 1
    self.pre = (ch > self.minHeal and ch or self.minHeal) * self.m * m * self.v * self.wf * nd
    self.currentClr = (self.goet and b and self.clrUseTwo) or (self.goet and self.clr) or self.clrUseTwo
end
function f:Health()
    self.mh = UnitHealthMax(p)
    self.ch = UnitHealth(p)
    self.minHeal = self.mh * 0.05
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
    "SPELLS_CHANGED",
    "UNIT_HEALTH_FREQUENT",
    "UNIT_AURA",
    "SPELL_UPDATE_CHARGES",
    "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_TALENT_UPDATE",
    "COMBAT_RATING_UPDATE",
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
            elseif se == "SPELL_CAST_SUCCESS" and select(4,...) == id and select(12,...) == 22842 then
                s.lastHeal = s.pre
            end
        elseif e == "SPELLS_CHANGED" then
            s:UpdateArtifactTraits()
        elseif e == "SPELL_UPDATE_CHARGES" then
            s.charges = GetSpellCharges(s.frenzied)
        elseif e == "PLAYER_TALENT_UPDATE" then
            s:TalentsUpdated()
        elseif e == "COMBAT_RATING_UPDATE" then
            s:StatsUpdated()
        elseif e == "UNIT_ABSORB_AMOUNT_CHANGED" then
            s.absorbs = UnitGetTotalAbsorbs(p)
        else
            s:Clean()
            f:Health()
            s:Predict()
            local n,_,_,_,_,d,e = UnitBuff(p ,s.frenzied)
            s.hotRemaining = n and (e-GetTime()) / d * s.lastHeal or 0
        end
end)
f:Init()
aura_env.f = f
