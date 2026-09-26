-- Derived from Keepward 1.4.10; see LICENSE-Keepward.txt.
-- Modified for BuffTap; this file is excluded from the MPL grant.

local _, NS = ...

-- kind: group, single, self, weapon, aura, aspect, tracking, blessing, seal, pet
-- covers: aura names that count as this buff already being up
-- ranks: highest first; resolved against the spellbook at login
NS.Buffs = {
  -- Druid
  { key="gotw", class="DRUID", kind="group", name="Gift of the Wild", covers={"Mark of the Wild","Gift of the Wild"}, ranks={21850,21849}, singleKey="motw", minNeed=3, defaultOn=true },
  { key="motw", class="DRUID", kind="single", name="Mark of the Wild", covers={"Mark of the Wild","Gift of the Wild"}, ranks={9885,9884,8907,5234,6756,5232,1126}, groupKey="gotw", defaultOn=true },
  { key="thorns", class="DRUID", kind="single", name="Thorns", covers={"Thorns"}, ranks={9910,9756,8914,1075,782,467}, target={"WARRIOR","PALADIN","DRUID"}, defaultOn=true },
  { key="omen", class="DRUID", kind="self", name="Omen of Clarity", covers={"Omen of Clarity"}, ranks={16864}, defaultOn=true },
  { key="natures-grasp", class="DRUID", kind="self", name="Nature's Grasp", covers={"Nature's Grasp"}, ranks={17329,16813,16812,16811,16810,16689}, defaultOn=false },

  -- Mage
  { key="ab", class="MAGE", kind="group", name="Arcane Brilliance", covers={"Arcane Intellect","Arcane Brilliance"}, ranks={23028}, singleKey="ai", minNeed=3, defaultOn=true },
  { key="ai", class="MAGE", kind="single", name="Arcane Intellect", covers={"Arcane Intellect","Arcane Brilliance"}, ranks={10157,10156,1461,1460,1459}, groupKey="ab", defaultOn=true },
  { key="mage-armor", class="MAGE", kind="self", name="Mage Armor", covers={"Mage Armor","Ice Armor","Frost Armor"}, ranks={22783,22782,6117}, defaultOn=true },
  { key="ice-armor", class="MAGE", kind="self", name="Ice Armor", covers={"Mage Armor","Ice Armor","Frost Armor"}, ranks={10220,10219,7320,7302}, defaultOn=false },
  { key="frost-armor", class="MAGE", kind="self", name="Frost Armor", covers={"Mage Armor","Ice Armor","Frost Armor"}, ranks={7301,7300,168}, defaultOn=false },
  { key="dampen", class="MAGE", kind="single", name="Dampen Magic", covers={"Dampen Magic","Amplify Magic"}, ranks={10174,10173,8451,8450,604}, defaultOn=false },
  { key="amplify", class="MAGE", kind="single", name="Amplify Magic", covers={"Dampen Magic","Amplify Magic"}, ranks={10170,10169,8455,1008}, defaultOn=false },

  -- Priest
  { key="pof", class="PRIEST", kind="group", name="Prayer of Fortitude", covers={"Power Word: Fortitude","Prayer of Fortitude"}, ranks={21564,21562}, singleKey="fort", minNeed=3, defaultOn=true },
  { key="fort", class="PRIEST", kind="single", name="Power Word: Fortitude", covers={"Power Word: Fortitude","Prayer of Fortitude"}, ranks={10938,10937,2791,1245,1244,1243}, groupKey="pof", defaultOn=true },
  { key="pos", class="PRIEST", kind="group", name="Prayer of Spirit", covers={"Divine Spirit","Prayer of Spirit"}, ranks={27681}, singleKey="spirit", minNeed=3, defaultOn=true },
  { key="spirit", class="PRIEST", kind="single", name="Divine Spirit", covers={"Divine Spirit","Prayer of Spirit"}, ranks={27841,14819,14818,14752}, groupKey="pos", defaultOn=true },
  { key="posp", class="PRIEST", kind="group", name="Prayer of Shadow Protection", covers={"Shadow Protection","Prayer of Shadow Protection"}, ranks={27683}, singleKey="sp", minNeed=3, defaultOn=false },
  { key="sp", class="PRIEST", kind="single", name="Shadow Protection", covers={"Shadow Protection","Prayer of Shadow Protection"}, ranks={10958,10957,976}, groupKey="posp", defaultOn=false },
  { key="inner-fire", class="PRIEST", kind="self", name="Inner Fire", covers={"Inner Fire"}, ranks={10952,10951,1006,602,7128,588}, defaultOn=true },
  { key="fear-ward", class="PRIEST", kind="single", name="Fear Ward", covers={"Fear Ward"}, ranks={6346}, defaultOn=false },
  { key="shadowform", class="PRIEST", kind="self", name="Shadowform", covers={"Shadowform"}, ranks={15473}, defaultOn=false },
  { key="shadowguard", class="PRIEST", kind="self", name="Shadowguard", covers={"Shadowguard"}, ranks={19312,19311,19310,19309,19308,18137}, defaultOn=false },
  { key="touch-weakness", class="PRIEST", kind="self", name="Touch of Weakness", covers={"Touch of Weakness"}, ranks={19266,19265,19264,19262,19261,2652}, defaultOn=false },

  -- Paladin
  { key="gbok", class="PALADIN", kind="blessing", name="Greater Blessing of Kings", covers={"Blessing of Kings","Greater Blessing of Kings"}, ranks={25898}, singleKey="bok", minNeed=2, defaultOn=true },
  { key="bok", class="PALADIN", kind="blessing", name="Blessing of Kings", covers={"Blessing of Kings","Greater Blessing of Kings"}, ranks={20217}, groupKey="gbok", defaultOn=true },
  { key="gbom", class="PALADIN", kind="blessing", name="Greater Blessing of Might", covers={"Blessing of Might","Greater Blessing of Might"}, ranks={25916,25782}, singleKey="bom", minNeed=2, target={"WARRIOR","ROGUE","HUNTER","PALADIN"}, defaultOn=true },
  { key="bom", class="PALADIN", kind="blessing", name="Blessing of Might", covers={"Blessing of Might","Greater Blessing of Might"}, ranks={25291,19838,19837,19836,19835,19834,19740}, groupKey="gbom", target={"WARRIOR","ROGUE","HUNTER","PALADIN"}, defaultOn=true },
  { key="gbow", class="PALADIN", kind="blessing", name="Greater Blessing of Wisdom", covers={"Blessing of Wisdom","Greater Blessing of Wisdom"}, ranks={25918,25894}, singleKey="bow", minNeed=2, target={"MAGE","WARLOCK","PRIEST","SHAMAN","DRUID","PALADIN"}, defaultOn=true },
  { key="bow", class="PALADIN", kind="blessing", name="Blessing of Wisdom", covers={"Blessing of Wisdom","Greater Blessing of Wisdom"}, ranks={25290,19854,19853,19852,19850,19742}, groupKey="gbow", target={"MAGE","WARLOCK","PRIEST","SHAMAN","DRUID","PALADIN"}, defaultOn=true },
  { key="gbos", class="PALADIN", kind="blessing", name="Greater Blessing of Salvation", covers={"Blessing of Salvation","Greater Blessing of Salvation"}, ranks={25895}, singleKey="bos", minNeed=2, defaultOn=false },
  { key="bos", class="PALADIN", kind="blessing", name="Blessing of Salvation", covers={"Blessing of Salvation","Greater Blessing of Salvation"}, ranks={1038}, groupKey="gbos", defaultOn=false },
  { key="gbol", class="PALADIN", kind="blessing", name="Greater Blessing of Light", covers={"Blessing of Light","Greater Blessing of Light"}, ranks={25890}, singleKey="bol", minNeed=2, defaultOn=false },
  { key="bol", class="PALADIN", kind="blessing", name="Blessing of Light", covers={"Blessing of Light","Greater Blessing of Light"}, ranks={19979,19978,19977}, groupKey="gbol", defaultOn=false },
  { key="righteous-fury", class="PALADIN", kind="self", name="Righteous Fury", covers={"Righteous Fury"}, ranks={25780}, defaultOn=false },
  { key="devotion", class="PALADIN", kind="aura", name="Devotion Aura", covers={"Devotion Aura","Retribution Aura","Concentration Aura","Fire Resistance Aura","Frost Resistance Aura","Shadow Resistance Aura"}, ranks={10293,10292,10291,643,1032,10290,465}, defaultOn=true },
  { key="retribution", class="PALADIN", kind="aura", name="Retribution Aura", covers={"Devotion Aura","Retribution Aura","Concentration Aura","Fire Resistance Aura","Frost Resistance Aura","Shadow Resistance Aura"}, ranks={10301,10300,10299,10298,7294}, defaultOn=false },
  { key="concentration", class="PALADIN", kind="aura", name="Concentration Aura", covers={"Devotion Aura","Retribution Aura","Concentration Aura","Fire Resistance Aura","Frost Resistance Aura","Shadow Resistance Aura"}, ranks={19746}, defaultOn=false },
  { key="shadow-res-aura", class="PALADIN", kind="aura", name="Shadow Resistance Aura", covers={"Devotion Aura","Retribution Aura","Concentration Aura","Fire Resistance Aura","Frost Resistance Aura","Shadow Resistance Aura"}, ranks={19896,19895,19876}, defaultOn=false },
  { key="frost-res-aura", class="PALADIN", kind="aura", name="Frost Resistance Aura", covers={"Devotion Aura","Retribution Aura","Concentration Aura","Fire Resistance Aura","Frost Resistance Aura","Shadow Resistance Aura"}, ranks={19898,19897,19888}, defaultOn=false },
  { key="fire-res-aura", class="PALADIN", kind="aura", name="Fire Resistance Aura", covers={"Devotion Aura","Retribution Aura","Concentration Aura","Fire Resistance Aura","Frost Resistance Aura","Shadow Resistance Aura"}, ranks={19900,19899,19891}, defaultOn=false },
  { key="sense-undead", class="PALADIN", kind="tracking", name="Sense Undead", covers={"Sense Undead"}, ranks={5502}, defaultOn=false },
  { key="seal-righteousness", class="PALADIN", kind="seal", name="Seal of Righteousness", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={20293,20292,20291,20290,20289,20287,20154,21084}, defaultOn=true },
  { key="seal-crusader", class="PALADIN", kind="seal", name="Seal of the Crusader", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={20308,20307,20306,20305,20162,21082}, defaultOn=false },
  { key="seal-command", class="PALADIN", kind="seal", name="Seal of Command", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={20920,20919,20918,20915,20375}, defaultOn=false },
  { key="seal-justice", class="PALADIN", kind="seal", name="Seal of Justice", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={20164}, defaultOn=false },
  { key="seal-light", class="PALADIN", kind="seal", name="Seal of Light", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={20349,20348,20347,20165}, defaultOn=false },
  { key="seal-wisdom", class="PALADIN", kind="seal", name="Seal of Wisdom", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={20357,20356,20166}, defaultOn=false },
  { key="seal-fury", class="PALADIN", kind="seal", name="Seal of Fury", covers={"Seal of Fury","Seal of Righteousness","Seal of the Crusader","Seal of Command","Seal of Justice","Seal of Light","Seal of Wisdom"}, ranks={1311656,1311649}, defaultOn=false },

  -- Warrior
  { key="battle-shout", class="WARRIOR", kind="group", name="Battle Shout", ranks={25289,11551,11550,11549,6192,5242,6673}, covers={"Battle Shout"}, defaultOn=true },

  -- Hunter
  { key="aspect-hawk", class="HUNTER", kind="aspect", name="Aspect of the Hawk", covers={"Aspect of the Hawk","Aspect of the Monkey","Aspect of the Cheetah","Aspect of the Pack","Aspect of the Wild","Aspect of the Beast"}, ranks={25296,14322,14321,14320,14319,14318,13165}, defaultOn=true },
  { key="aspect-monkey", class="HUNTER", kind="aspect", name="Aspect of the Monkey", covers={"Aspect of the Hawk","Aspect of the Monkey","Aspect of the Cheetah","Aspect of the Pack","Aspect of the Wild","Aspect of the Beast"}, ranks={13163}, defaultOn=false },
  { key="aspect-cheetah", class="HUNTER", kind="aspect", name="Aspect of the Cheetah", covers={"Aspect of the Hawk","Aspect of the Monkey","Aspect of the Cheetah","Aspect of the Pack","Aspect of the Wild","Aspect of the Beast"}, ranks={5118}, defaultOn=false },
  { key="aspect-beast", class="HUNTER", kind="aspect", name="Aspect of the Beast", covers={"Aspect of the Hawk","Aspect of the Monkey","Aspect of the Cheetah","Aspect of the Pack","Aspect of the Wild","Aspect of the Beast"}, ranks={1299447,1299446,1299445,13161}, defaultOn=false },
  { key="aspect-pack", class="HUNTER", kind="aspect", name="Aspect of the Pack", covers={"Aspect of the Hawk","Aspect of the Monkey","Aspect of the Cheetah","Aspect of the Pack","Aspect of the Wild","Aspect of the Beast"}, ranks={13159}, defaultOn=false },
  { key="aspect-wild", class="HUNTER", kind="aspect", name="Aspect of the Wild", covers={"Aspect of the Hawk","Aspect of the Monkey","Aspect of the Cheetah","Aspect of the Pack","Aspect of the Wild","Aspect of the Beast"}, ranks={20190,20043}, defaultOn=false },
  { key="trueshot", class="HUNTER", kind="group", name="Trueshot Aura", covers={"Trueshot Aura"}, ranks={20906,20905,19506}, defaultOn=true },
  { key="track-beasts", class="HUNTER", kind="tracking", name="Track Beasts", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={1494}, defaultOn=true },
  { key="track-humanoids", class="HUNTER", kind="tracking", name="Track Humanoids", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19883}, defaultOn=false },
  { key="track-undead", class="HUNTER", kind="tracking", name="Track Undead", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19884}, defaultOn=false },
  { key="track-hidden", class="HUNTER", kind="tracking", name="Track Hidden", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19885}, defaultOn=false },
  { key="track-elementals", class="HUNTER", kind="tracking", name="Track Elementals", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19880}, defaultOn=false },
  { key="track-demons", class="HUNTER", kind="tracking", name="Track Demons", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19878}, defaultOn=false },
  { key="track-giants", class="HUNTER", kind="tracking", name="Track Giants", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19882}, defaultOn=false },
  { key="track-dragonkin", class="HUNTER", kind="tracking", name="Track Dragonkin", covers={"Track Beasts","Track Humanoids","Track Undead","Track Hidden","Track Elementals","Track Demons","Track Giants","Track Dragonkin"}, ranks={19879}, defaultOn=false },
  { key="revive-pet", class="HUNTER", kind="pet", name="Revive Pet", covers={}, ranks={982}, defaultOn=true },

  -- Shaman
  { key="water-shield", class="SHAMAN", kind="self", name="Water Shield", covers={"Water Shield","Lightning Shield"}, ranks={408510}, defaultOn=false },
  { key="lightning-shield", class="SHAMAN", kind="self", name="Lightning Shield", covers={"Lightning Shield","Water Shield"}, ranks={10432,10431,8134,945,325,905,324}, defaultOn=true },
  { key="windfury", class="SHAMAN", kind="weapon", name="Windfury Weapon", covers={"Windfury Weapon","Flametongue Weapon","Rockbiter Weapon","Frostbrand Weapon"}, ranks={16362,10486,8235,8232}, defaultOn=true },
  { key="flametongue", class="SHAMAN", kind="weapon", name="Flametongue Weapon", covers={"Windfury Weapon","Flametongue Weapon","Rockbiter Weapon","Frostbrand Weapon"}, ranks={16342,16341,16339,8030,8027,8024}, defaultOn=false },
  { key="frostbrand", class="SHAMAN", kind="weapon", name="Frostbrand Weapon", covers={"Windfury Weapon","Flametongue Weapon","Rockbiter Weapon","Frostbrand Weapon"}, ranks={16356,16355,10456,8038,8033}, defaultOn=false },
  { key="rockbiter", class="SHAMAN", kind="weapon", name="Rockbiter Weapon", covers={"Windfury Weapon","Flametongue Weapon","Rockbiter Weapon","Frostbrand Weapon"}, ranks={16316,16315,16314,10399,8019,8018,8017}, defaultOn=false },
  { key="water-breathing", class="SHAMAN", kind="single", name="Water Breathing", covers={"Water Breathing"}, ranks={131}, defaultOn=false },
  { key="water-walking", class="SHAMAN", kind="single", name="Water Walking", covers={"Water Walking"}, ranks={546}, defaultOn=false },

  -- Warlock
  { key="demon-armor", class="WARLOCK", kind="self", name="Demon Armor", covers={"Demon Armor","Demon Skin"}, ranks={11735,11734,11733,1086}, defaultOn=true },
  { key="demon-skin", class="WARLOCK", kind="self", name="Demon Skin", covers={"Demon Armor","Demon Skin"}, ranks={706,696,687}, defaultOn=false },
  { key="unending-breath", class="WARLOCK", kind="single", name="Unending Breath", covers={"Unending Breath"}, ranks={5697}, defaultOn=false },
  { key="detect-invis", class="WARLOCK", kind="single", name="Detect Invisibility", covers={"Detect Invisibility"}, ranks={132,2970,11743}, defaultOn=false },
  { key="soul-link", class="WARLOCK", kind="self", name="Soul Link", covers={"Soul Link"}, ranks={19028}, defaultOn=true },

  -- Rogue
  { key="instant-poison", class="ROGUE", kind="weapon", name="Instant Poison", covers={"Instant Poison"}, ranks={11340,11339,11338,8687,8681,8679}, defaultOn=true },
  { key="deadly-poison", class="ROGUE", kind="weapon", name="Deadly Poison", covers={"Deadly Poison"}, ranks={25351,11356,11355,11354,2835}, defaultOn=true },
  { key="crippling-poison", class="ROGUE", kind="weapon", name="Crippling Poison", covers={"Crippling Poison"}, ranks={3421,3408}, defaultOn=false },
  { key="mind-poison", class="ROGUE", kind="weapon", name="Mind-numbing Poison", covers={"Mind-numbing Poison"}, ranks={11399,8694,5763}, defaultOn=false },
  { key="wound-poison", class="ROGUE", kind="weapon", name="Wound Poison", covers={"Wound Poison"}, ranks={13230,13229,13228,13220}, defaultOn=false },

  -- Gathering
  { key="find-herbs", class="ALL", kind="tracking", name="Find Herbs", covers={"Find Herbs","Find Minerals","Find Treasure","Find Fish"}, ranks={2383}, defaultOn=false },
  { key="find-minerals", class="ALL", kind="tracking", name="Find Minerals", covers={"Find Herbs","Find Minerals","Find Treasure","Find Fish"}, ranks={2580}, defaultOn=false },


}


-- Curated Forever maintenance consumables. This is intentionally small and
-- whitelist-only: unknown consumables never become secure actions.
NS.ForeverDataBuild = "1.60.1.70009"
NS.EatingSpellIDs = {[1131]=true,[1248400]=true,[1248401]=true}
NS.CampBenefitsSpellID = 1229741
-- Exact hidden auras used by Forever's Camp Benefits tooltip. These are
-- recognition-only; similar stats do not suppress class-buff reminders.
NS.CampAdditions = {
  {key="tent",name="Camp Tent",auraID=1229451},
  {key="mana-well",name="Mana Well",auraID=1230587},
  {key="sharpening-wheel",name="Sharpening Wheel",auraID=1230172},
  {key="enchanted-lute",name="Enchanted Lute",auraID=1230653},
  {key="first-aid",name="First Aid Kit",auraID=1230124},
  {key="fish-bowl",name="Fish Bowl",auraID=1230098},
  {key="incense",name="Incense Candle",auraID=1229513},
  {key="lodestone",name="Lodestone",auraID=1230164},
  {key="chair",name="Camp Chair",auraID=1229519},
  {key="banner",name="Faction Banner",auraID=1229718},
}
NS.ConsumableFamilies = {
  {
    key="food", name="Food", defaultOn=false, defaultSeconds=300, pendingSeconds=14,
    -- Any recognized Well Fed effect satisfies the family. This conservative
    -- rule avoids replacing another food buff just because it is not our chosen food.
    auraNames={"Well Fed"}, localizedAuraSpellIDs={19705,24799,1248421,1248422}, includeItemSpell=false,
    items={
      {id=250071,useSpell=1248401,auraIDs={1248422},name="Steaming Stag Steak",note="20 Strength / 15 min"},
      {id=250067,useSpell=1248400,auraIDs={1248421},name="Bat Hachee",note="20 Intellect / 15 min"},
    },
  },
  {
    key="flask", name="Flask", defaultOn=false, defaultSeconds=600, pendingSeconds=2,
    -- All nine current Forever flask names satisfy this family, including
    -- Petrification (recognized but not offered as a maintenance choice).
    auraSpellIDs={17626,17627,17628,17629,17624,1293740,1293741,1293742,1293743},
    auraNames={"Flask of Distilled Wisdom","Flask of Natural Accuracy","Flask of Natural Aggression",
      "Flask of Natural Precision","Flask of Natural Swiftness","Flask of Supreme Power",
      "Flask of Petrification","Flask of the Titans","Flask of Chromatic Resistance"},
    items={
      {id=274273,useSpell=1293740,auraIDs={1293740},name="Flask of Natural Accuracy",note="Forever"},
      {id=274274,useSpell=1293741,auraIDs={1293741},name="Flask of Natural Aggression",note="Forever"},
      {id=274275,useSpell=1293742,auraIDs={1293742},name="Flask of Natural Precision",note="Forever"},
      {id=274276,useSpell=1293743,auraIDs={1293743},name="Flask of Natural Swiftness",note="Forever"},
      {id=13510,useSpell=17626,auraIDs={17626},name="Flask of the Titans",note="Classic"},
      {id=13511,useSpell=17627,auraIDs={17627},name="Flask of Distilled Wisdom",note="Classic"},
      {id=13512,useSpell=17628,auraIDs={17628},name="Flask of Supreme Power",note="Classic"},
      {id=13513,useSpell=17629,auraIDs={17629},name="Flask of Chromatic Resistance",note="Classic"},
    },
  },
  {
    key="ferocity", name="Elixir of Ferocity", defaultOn=false, defaultSeconds=180, pendingSeconds=2,
    auraNames={"Elixir of Ferocity"},
    items={{id=250350,useSpell=1250985,auraIDs={1250985},name="Elixir of Ferocity",note="18 Strength & Agility / 30 min"}},
  },
}

NS.SOUNDKIT_REMIND = 12867 -- ALARM_CLOCK_WARNING_2, safe on Forever (no PlaySoundFile ogg paths)

-- Vanilla-era minimum levels for each rank id (fallback if the client
-- does not expose C_Spell.GetSpellLevelLearned). Highest ranks first
-- in each buff's ranks list; this table is keyed by spell id.
NS.RankLevel = {
  -- Druid MotW / GotW / Thorns
  [1126]=1,[5232]=10,[6756]=20,[5234]=30,[8907]=40,[9884]=50,[9885]=60,
  [21849]=50,[21850]=60,
  [467]=6,[782]=14,[1075]=24,[8914]=34,[9756]=44,[9910]=54,
  [16864]=20,[16689]=10,[16810]=18,[16811]=28,[16812]=38,[16813]=48,[17329]=58,
  -- Mage
  [1459]=1,[1460]=14,[1461]=28,[10156]=42,[10157]=56,[23028]=56,
  [6117]=34,[22782]=46,[22783]=58,[168]=1,[7300]=10,[7301]=20,[7302]=30,[7320]=40,[10219]=50,[10220]=60,
  [604]=12,[8450]=24,[8451]=36,[10173]=48,[10174]=60,
  [1008]=18,[8455]=30,[10169]=42,[10170]=54,
  -- Priest
  [1243]=1,[1244]=12,[1245]=24,[2791]=36,[10937]=48,[10938]=60,
  [21562]=48,[21564]=60,
  [14752]=30,[14818]=40,[14819]=50,[27841]=60,[27681]=60,
  [976]=30,[10957]=42,[10958]=56,[27683]=56,
  [588]=12,[7128]=20,[602]=30,[1006]=40,[10951]=50,[10952]=60,
  [6346]=20,[15473]=40,
  [18137]=20,[19308]=28,[19309]=36,[19310]=44,[19311]=52,[19312]=60,
  [2652]=10,[19261]=20,[19262]=30,[19264]=40,[19265]=50,[19266]=60,
  -- Paladin
  [20217]=20,[25898]=60,
  [19740]=4,[19834]=12,[19835]=22,[19836]=32,[19837]=42,[19838]=52,[25291]=60,
  [25782]=52,[25916]=60,
  [19742]=14,[19850]=24,[19852]=34,[19853]=44,[19854]=54,[25290]=60,
  [25894]=54,[25918]=60,
  [1038]=26,[25895]=60,[25780]=16,
  [19977]=40,[19978]=50,[19979]=60,[25890]=60,
  [19746]=22,[5502]=20,
  [19876]=28,[19895]=40,[19896]=52,
  [19888]=32,[19897]=42,[19898]=54,
  [19891]=36,[19899]=46,[19900]=56,
  [465]=1,[10290]=10,[643]=20,[10291]=30,[1032]=40,[10292]=50,[10293]=60,
  [7294]=16,[10298]=26,[10299]=36,[10300]=46,[10301]=56,
  [21084]=1,[20154]=8,[20287]=16,[20288]=22,[20289]=30,[20290]=38,[20291]=46,[20292]=54,[20293]=60,
  [21082]=6,[20162]=12,[20305]=22,[20306]=32,[20307]=42,[20308]=52,
  [20375]=20,[20915]=30,[20918]=40,[20919]=50,[20920]=60,
  [20165]=30,[20347]=40,[20348]=50,[20349]=60,
  [20166]=38,[20356]=48,[20357]=58,
  [20164]=22,[1311649]=10,[1311656]=18,
  -- Warrior
  [6673]=1,[5242]=12,[6192]=22,[11549]=32,[11550]=42,[11551]=52,[25289]=60,
  -- Hunter
  [13165]=10,[14318]=18,[14319]=28,[14320]=38,[14321]=48,[14322]=58,[25296]=60,
  [13163]=4,[5118]=20,[13161]=30,[13159]=40,[20043]=46,[20190]=56,
  [1299445]=40,[1299446]=50,[1299447]=60,
  [19506]=25,[20905]=50,[20906]=60,
  [1494]=1,[19883]=10,[19884]=18,[19885]=24,[19880]=26,[19878]=32,[19882]=40,[19879]=50,[982]=10,
  -- Shaman
  [324]=8,[325]=16,[905]=24,[945]=32,[8134]=40,[10431]=48,[10432]=56,[408510]=20,
  [8232]=30,[8235]=40,[10486]=50,[16362]=60,
  [8024]=10,[8027]=18,[8030]=26,[16339]=36,[16341]=46,[16342]=56,
  [8033]=20,[8038]=28,[10456]=38,[16355]=48,[16356]=58,
  [8017]=1,[8018]=8,[8019]=16,[10399]=24,[16314]=34,[16315]=44,[16316]=54,
  [131]=22,[546]=28,
  -- Warlock
  [687]=1,[696]=10,[706]=20,[1086]=20,[11733]=30,[11734]=40,[11735]=50,
  [5697]=16,[132]=26,[2970]=38,[11743]=50,[19028]=20,
  -- Rogue
  [8679]=20,[8681]=28,[8687]=36,[11338]=44,[11339]=52,[11340]=60,
  [2835]=30,[11354]=38,[11355]=46,[11356]=54,[25351]=60,
  [3408]=20,[3421]=50,
  [5763]=24,[8694]=38,[11399]=52,
  [13220]=32,[13228]=40,[13229]=48,[13230]=56,
  -- Gathering
  [2383]=1,[2580]=1,
}

-- Group reagents from Forever 1.60.1.70009; checked only for candidate casts.
NS.GroupReagents = {
  [21562]={{17028,1}},
  [21564]={{17029,1}},
  [21849]={{17021,1}},
  [21850]={{17026,1}},
  [23028]={{17020,1}},
  [25782]={{21177,1}},
  [25890]={{21177,1}},
  [25894]={{21177,1}},
  [25895]={{21177,1}},
  [25898]={{21177,1}},
  [25916]={{21177,1}},
  [25918]={{21177,1}},
  [27681]={{17029,1}},
  [27683]={{17029,1}},
}
