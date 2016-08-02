local p = "player"
local f = CreateFrame("Frame", "BMHB")
local events = {
  PLAYER_TALENT_UPDATE = function(s,...)
    s.healingElixirSelected = select(4, GetTalentInfo(5,1,1))
    if not s.healingElixirSelected then
      s.healingElixirHeal = 0
      s.healingElixirCharges = 0
    else
      s:HealingElixirHeal()
    end
  end,
  UNIT_HEALTH_FREQUENT = function(s,...)
    s.health = UnitHealth(p)
    s.healthMax = UnitHealthMax(p)
  end,
  SPELL_UPDATE_CHARGES = function(s,...)
    if s.healingElixirSelected then
      s.healingElixirCharges = GetSpellCharges(s.healingElixir)
      s:HealingElixirHeal()
    end
  end,
  UNIT_ABSORB_AMOUNT_CHANGED = function(s,...)
    s.absorbs = UnitGetTotalAbsorbs(p)
    s.absorbsBar = {s.giftOfTheOxHeal + s.absorbs, 2 * s.healthMax, true}
  end,
  COMBAT_RATING_UPDATE = function(s,...)
    s.versatility = (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)) / 100 + 1
    s.crit = GetCritChance() / 100 + 1
  end
}
function f:Init()
  self.health = 0
  self.healthMax = 0
  self.healingElixir = GetSpellInfo(122280)
  self.expelHarm = GetSpellInfo(115072)
  self.giftOfTheOx = GetSpellInfo(124502)
  self.celestialModifier = 0.65
  self.healingElixirModifier = 0.15
  self.giftOfTheOxCount = 0
  self.giftOfTheOxHeal = 0
  self.healingElixirCharges = 0
  self.healingElixirHeal = 0
  self.absorbs = 0
  for _,f in pairs(events) do
    f(self)
  end
end
function f:ApplyCrit(value)
  return value * self.crit
end
function f:ApplyCelestialFortune(value)
  return value * self.crit * self.celestialModifier
end
function f:ApplyVersatility(value)
  return value * self.versatility
end
function f:GiftOfTheOxHeal()
  local integerPlace, decimalPlace = GetSpellDescription(self.giftOfTheOx):match("(%d+)%p(%d+)")
  local heal = tonumber(integerPlace .. decimalPlace)
  self.giftOfTheOxHeal = self:ApplyCelestialFortune(self:ApplyCrit(self:ApplyVersatility(self.giftOfTheOxCount * heal)))
end
function f:HealingElixirHeal()
  self.healingElixirHeal = self:ApplyCelestialFortune(self:ApplyVersatility(self.healthMax * self.healingElixirModifier * self.healingElixirCharges))
end
f:Init()
for e,_ in pairs(events) do
  f:RegisterEvent(e)
end
f:SetScript("OnEvent",function(s,e,...)
  events[e](s,...)
end)
local freq = 0.2
local sinceLastUpdate = 0
f:SetScript("OnUpdate",function(s,elapsed)
  s.giftOfTheOxCount = GetSpellCount(s.expelHarm)
  s:GiftOfTheOxHeal()
end)
aura_env.f = f
