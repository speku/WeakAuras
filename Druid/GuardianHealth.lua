local p = "player"
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
function f:Init()
  self.clrUseTwo = {0,1,0,1}
  self.clrUseOne = {0,0.8,0,1}
  self.clr = {0,0.6,0,1}
  self.currentClr = self.clr
  self.dmgs = {}
  self.mastery = GetSpellInfo(155783)
  self.frenzied = GetSpellInfo(22842)
  self.goe = GetSpellInfo(155578)
  self.m = 1
  self.dmg = 0
  self.sinceLastUpdate = 0
  self.freq = 0.2
  self.hotRemaining = 0
  self.ch = UnitHealth(p)
  self.mh = UnitHealthMax(p)
  self.minHeal = self.mh * 0.05
  self.pre = 0
  self.charges, self.maxCharges = GetSpellCharges(self.frenzied)
  self:UpdateArtifactTraits()
end
function f:Predict()
  local ch = self.dmg * 0.5
  local m = UnitBuff(p,self.goe) and 1.2 or 1
  local v = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) / 100 + 1
  local pre = (ch > self.minHeal and ch or self.minHeal) * self.m * m * v * self.wf
  self.currentClr = self.ch + self.hotRemaining + pre > self.mh and self.clr or self.charges < self.maxCharges and self.clrUseOne or self.clrUseTwo
  return pre
end
f:SetScript("OnUpdate",function(s,elapsed)
        s.sinceLastUpdate = s.sinceLastUpdate + elapsed
        if s.sinceLastUpdate >= s.freq then
            s.sinceLastUpdate = 0
            local delete = {}
            for expire,dmg in pairs(s.dmgs) do
                if GetTime() >= expire then
                    s.dmg = s.dmg - dmg
                    table.insert(delete,expire)
                end
            end
            for _,t in pairs(delete) do
                s.dmgs[t] = nil
            end
            s.m = tonumber(GetSpellDescription(f.mastery):match("%d+")) / 100 + 1
            s.pre = s:Predict()
        end
end)
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("UNIT_HEALTH_FREQUENT")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("SPELL_UPDATE_CHARGES")
f:SetScript("OnEvent", function(s,e,...)
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
        local id = UnitGUID(p)
        if e == "COMBAT_LOG_EVENT_UNFILTERED" then
            if select(8,...) == id and relevantDmg[select(2,...)] then
                local dmg = extract(...)
                s.dmg = s.dmg + dmg
                s.dmgs[GetTime()+5] = dmg
                s.pre = s:Predict()
            elseif select(2,...) == "SPELL_CAST_SUCCESS" and select(4,...) == id and select(12,...) == 22842 then
                s.lastHeal = s:Predict()
            end
        elseif e == "SPELLS_CHANGED" then
          s:UpdateArtifactTraits()
        elseif e == "SPELL_UPDATE_CHARGES" then
          s.charges = GetSpellCharges(s.frenzied)
        else
            if e == "UNIT_HEALTH_FREQUENT" then
                s.mh = UnitHealthMax(p)
                s.ch = UnitHealth(p)
                s.minHeal = s.mh * 0.05
            end
            local n,_,_,_,_,d,e = UnitBuff(p ,s.frenzied)
            s.hotRemaining = n and (e-GetTime()) / d * s.lastHeal or 0
        end
end)
f:Init()
aura_env.f = f
