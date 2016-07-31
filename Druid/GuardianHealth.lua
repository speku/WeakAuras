local f = CreateFrame("Frame","GDFRP")
f.dmgs = {}
f.mastery = GetSpellInfo(155783)
f.frenzied = GetSpellInfo(22842)
f.m = 1
f.dmg = 0
f.sinceLastUpdate = 0
f.freq = 0.2
f.hotRemaining = 0
f.ch = 0
f.mh = 0
f.pre = 0
f:SetScript("OnUpdate",function(s,elapsed)
        s.sinceLastUpdate = s.sinceLastUpdate + elapsed
        if s.sinceLastUpdate >= s.freq then
            s.sinceLastUpdate = 0
            local delete = {}
            local time = GetTime()
            for expire,dmg in pairs(s.dmgs) do
                if time >= expire then
                    s.dmg = s.dmg - dmg
                    table.insert(delete,expire)
                end
            end
            for _,t in pairs(delete) do
                s.dmgs[t] = nil
            end
            do
                local n,_,_,_,_,d,e = UnitBuff("player",s.frenzied)
                s.hotRemaining = n and (e-time) / d * s.lastHeal or 0
            end
            s.mh = UnitHealthMax("player")
            s.ch = UnitHealth("player")
            s.m = tonumber(GetSpellDescription(f.mastery):match("%d+")) / 100 + 1
            s.minHeal = s.mh * 0.05
            local current = s.dmg * 0.5
            s.pre = (current > s.minHeal and current or s.minHeal) * s.m
        end
end)
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
        local p = UnitGUID("player")
        if e == "COMBAT_LOG_EVENT_UNFILTERED" then
            if select(8,...) == p and relevantDmg[select(2,...)] then
                local dmg = extract(...)
                s.dmg = s.dmg + dmg
                s.dmgs[GetTime()+5] = dmg
            elseif select(2,...) == "SPELL_CAST_SUCCESS" and select(4,...) == p and select(12,...) == 22842 then
                local current = s.dmg * 0.5
                s.lastHeal = current > s.minHeal and current or s.minHeal
            end
        end
end)
aura_env.f = f
