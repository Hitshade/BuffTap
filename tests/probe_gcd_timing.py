"""Compare published 1.26.0 with this working tree using a mocked 1.5s GCD."""
from pathlib import Path
import subprocess
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
addon = root / 'addon/BuffTap'
for revision in ('v1.26.0', 'working tree'):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((root/'tests/mock.lua').read_text())
    ns = lua.table()
    for line in (addon/'BuffTap.toc').read_text().splitlines():
        if not line.strip().endswith('.lua'):
            continue
        name = line.strip()
        if revision == 'working tree':
            source = (addon/name).read_text(encoding='utf-8-sig')
        else:
            source = subprocess.check_output(['git', 'show', f'{revision}:addon/BuffTap/{name}'], cwd=root).decode('utf-8-sig')
        lua.execute(source, 'BuffTap', ns)
    lua.execute("""
BuffTapDB={group=false,groupDefaultVersion=1,helperDismiss=false,helperDismissMinutes=0}
BuffTap:InitDB(); BuffTap:Refresh()
local B=BuffTap; local start=GetTime()
C_Spell.GetSpellCooldown=function()
 local active=GetTime()<start+1.5
 return {startTime=active and start or 0,duration=active and 1.5 or 0,
         isEnabled=true,isActive=active,isOnGCD=active}
end
C_Spell.GetSpellCooldownDuration=function(id,ignore)
 assert(ignore==true); return {GetRemainingDuration=function() return 0 end}
end
aura('player',5232,'Mark of the Wild'); B:InvalidateAura('player')
B:RequestRefresh('postclick',.12)
B.events.scripts.OnEvent(nil,'SPELL_UPDATE_COOLDOWN')
local first
for i=0,160 do
 if B.action and B.action.id==467 and bindings.MOUSEWHEELDOWN then first=GetTime()-start; break end
 advance(.01)
end
assert(first~=nil,'next buff was never prepared')
result=first
""")
    print(f'{revision}: next buff and binding ready after {lua.globals().result:.2f}s (mock GCD 1.50s)')
