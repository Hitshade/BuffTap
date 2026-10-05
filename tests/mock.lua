
now=100; combat=false; auras={}; spells={}; book={}; bindings={}; prints={}; dead=false; mounted=false; clearBindingCalls=0
Enum={SpellBookSpellBank={Player=0}}
function issecretvalue(v) return type(v)=='table' and v.secret==true end
function InCombatLockdown() return combat end
function GetTime() return now end
function UnitClass(u) return 'Druid',playerClass or 'DRUID' end
function UnitName(u) return u=='player' and 'Tester' or 'Ally' end
function UnitGUID(u) return 'Player-'..u end
function UnitExists(u) return u=='player' or u=='target' or u=='party1' or u=='party2' end
function UnitIsDeadOrGhost() return dead end
function IsMounted() return mounted end
function UnitLevel(u) return u=='player' and 60 or 10 end
function UnitIsConnected() return true end
function UnitCanAssist() return true end
function UnitIsUnit(a,b) return a==b end
function UnitCastingInfo() return nil end
function UnitChannelInfo() return nil end
function IsInRaid() return false end
function GetNumSubgroupMembers() return 2 end
function GetBuildInfo() return '1.60.1','70009','',16001 end
function PlaySound() end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
SlashCmdList={}; UISpecialFrames={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,s) prints[#prints+1]=s end}
C_Spell={
 GetSpellName=function(id) return spells[id] and spells[id].name end,
 GetSpellTexture=function(id) return spells[id] and spells[id].icon end,
 GetSpellLevelLearned=function(id) return spells[id] and spells[id].level end,
 GetSpellSubtext=function(id) return spells[id] and spells[id].rank end,
 IsSpellPassive=function(id) return spells[id] and spells[id].passive or false end,
 IsSpellUsable=function(id) return spells[id] and spells[id].usable~=false end,
 IsSpellInRange=function() return true end,
 GetSpellCooldown=function(id) return {startTime=0,duration=0,isEnabled=true} end,
}
C_SpellBook={
 IsSpellKnown=function(id) return spells[id] and spells[id].known==true or false end,
 GetNumSpellBookSkillLines=function() return 1 end,
 GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=#book} end,
 GetSpellBookItemInfo=function(i) local id=book[i]; local s=spells[id]; return {spellID=id,name=s.name,subName=s.rank,isPassive=s.passive or false,isOffSpec=false} end,
 GetSpellBookItemLevelLearned=function(i) return spells[book[i]].level end,
}
playerAuras={}
C_UnitAuras={
 GetAuraDataByIndex=function(u,i) return (auras[u] or {})[i] end,
 GetPlayerAuraBySpellID=function(id) return playerAuras[id] end,
}
local function noop() end
local function visual()
 return setmetatable({SetTexture=function(s,v) s.texture=v end,SetText=function(s,v) s.text=v end,SetShown=function(s,v) s.shown=not not v end,Show=function(s) s.shown=true end,Hide=function(s) s.shown=false end,IsShown=function(s) return s.shown end}, {__index=function() return noop end})
end
local methods={}
function methods:SetAttribute(k,v) assert(not combat or self.secure,'protected write in combat'); self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:Hide() assert(not combat or not self.protected or self.secure,'protected hide in combat'); self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:Show() assert(not combat or not self.protected or self.secure,'protected show in combat'); self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(e) self.registered[e]=true end
function methods:CreateTexture() return visual() end
function methods:CreateFontString() return visual() end
function methods:ClearBindings() bindings={} end
function methods:SetText(s) self.text=s end
function methods:GetText() return self.text end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:GetParent() return self.parent end
function methods:GetCenter() return 500,500 end
function methods:SetSize() assert(not combat or not self.protected,'protected resize') end
function methods:SetPoint() assert(not combat or not self.protected,'protected move') end
function CreateFrame(kind,name,parent,template)
 local f=setmetatable({attrs={},scripts={},registered={},shown=false,parent=parent,Text=visual(),Low=visual(),High=visual(),protected=template and template:find('Secure')~=nil}, {__index=function(_,k) return methods[k] or (k:match("^%u") and noop or nil) end})
 if name then _G[name]=f end
 return f
end
UIParent=CreateFrame('Frame'); GameTooltip=CreateFrame('Frame')
function ClearOverrideBindings(f) assert(not combat or f.secure,'binding mutation in combat'); clearBindingCalls=clearBindingCalls+1; bindings={} end
function SetOverrideBindingClick(f,p,key,name,button) assert(not combat); bindings[key]=name..':'..button end
function RegisterStateDriver(f,state,condition) f.attrs['state-'..state]='ready'; f.driver=condition end
function safety(state)
 local f=BuffTap.button; f.secure=true
 local fn=assert(loadstring('local self,newstate=...; '..f.attrs['_onstate-safety']))
 f.attrs['state-safety']=state; fn(f,state); f.secure=false
end
function seed()
 spells={
 [1126]={name='Mark of the Wild',icon=136078,rank='Rank 1',level=1,known=true},
 [5232]={name='Mark of the Wild',icon=136078,rank='Rank 2',level=10,known=true},
 [467]={name='Thorns',icon=136104,rank='Rank 1',level=6,known=true}}
 book={1126,5232,467}; auras={}; dead=false; mounted=false; combat=false; bindings={}
end
seed()

function methods:GetParent() return self.parent end
function methods:SetValue(v) self.value=v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
function methods:GetValue() return self.value end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function UnitIsVisible() return true end
function UnitIsPlayer() return true end
function GetBindingAction(key,overrides) return bindings[key] or "" end
timers={}
C_Timer={NewTimer=function(delay,fn)
 local t={due=now+delay,fn=fn,Cancel=function(self) self.cancelled=true end}
 timers[#timers+1]=t; return t
end}
C_Timer.After=function(d,f) C_Timer.NewTimer(d,f) end
function liveTimers() local n=0; for _,t in ipairs(timers) do if not t.cancelled and not t.fired then n=n+1 end end; return n end
function advance(dt)
 local target=now+dt; local steps=0
 while true do
  local earliest
  for _,t in ipairs(timers) do if not t.cancelled and not t.fired and t.due<=target and (not earliest or t.due<earliest.due) then earliest=t end end
  if not earliest then break end
  now=earliest.due; earliest.fired=true; earliest.fn(); steps=steps+1; assert(steps<10000,'timer loop')
 end
 now=target
end
items={}; bags={[17021]=20,[17026]=20,[21177]=20}; countCalls=0; equipped={}; weaponEnchants={}
C_Item={
 GetItemCount=function(id,bank,uses,reagent,account) assert(not bank and not reagent and not account); countCalls=countCalls+1; return bags[id] or 0 end,
 GetItemInfo=function(id) local i=items[id]; if i and i.loaded~=false then return i.name,'item:'..id,1,1,1,'Consumable','',20,'',i.icon end end,
 GetItemInfoInstant=function(id)
  local i=items[id]
  if i and i.weapon then return id,'Weapon','Sword',i.equipLoc or 'INVTYPE_WEAPON',i.icon,2,7 end
  if i and i.shield then return id,'Armor','Shields','INVTYPE_SHIELD',i.icon,4,6 end
  return id,'Consumable','','',i and i.icon
 end,
 GetItemSpell=function(id) local i=items[id]; return i and i.name,i and i.spell end,
 IsUsableItem=function(id) return items[id] and items[id].usable~=false or false end,
 GetItemCooldown=function(id) return 0,0,true end,
 RequestLoadItemDataByID=function(id) end,
}
C_PaperDollInfo={GetTemporaryEnchantmentInfo=function(slot) return weaponEnchants[slot] end}
function GetInventoryItemID(unit,slot) return equipped[slot] end
function GetInventoryItemTexture(unit,slot) return items[equipped[slot]] and items[equipped[slot]].icon end
function equipWeapon(slot,id) items[id]={name='Weapon '..id,icon=135274,weapon=true,equipLoc=slot==17 and 'INVTYPE_WEAPONOFFHAND' or 'INVTYPE_WEAPONMAINHAND'}; equipped[slot]=id end
function equipShield(slot,id) items[id]={name='Shield '..id,icon=134950,shield=true}; equipped[slot]=id end
function stock(id,spell)
 items[id]={name='Consumable '..id,icon=12345,spell=spell}; bags[id]=5
end
function spell(id,name,level) spells[id]={name=name,icon=12345,level=level or 1,rank='',known=true}; book[#book+1]=id; BuffTap.bookDirty=true end
function aura(u,id,name,remaining,duration)
 auras[u]=auras[u] or {}; table.insert(auras[u],{spellId=id,name=name,duration=duration or 1800,expirationTime=now+(remaining or 1800)})
 BuffTap:InvalidateAura(u)
end
function refresh() BuffTap:InvalidateAura(); BuffTap:Refresh() end
function consumables(family)
 for _,b in ipairs(BuffTap.Buffs) do BuffTap.db.buffs[b.key]=false end
 BuffTap.db.consumablesEnabled=true; BuffTap.db.consumableFamilies[family]=true; BuffTap:InvalidateConsumables()
end

function methods:UnregisterEvent(e) self.registered[e]=nil end
