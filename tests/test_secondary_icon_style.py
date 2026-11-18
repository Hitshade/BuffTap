from test_bufftap import test
from test_manual_consumables import BASE

def assertions(var, modern):
 return (f"assert({var}.buffTapIconStyle=='{'modern' if modern else 'classic'}'); "
         f"assert({var}.icon.coords[1]=={'.08' if modern else '0'}); "
         f"assert({var}.icon.coords[2]=={'.92' if modern else '1'}); "
         f"assert({var}.glow==nil and {var}.buffTapEffect==nil); "
         + (f"assert({var}.modernFrame and {var}.modernFrame.outer[1].shown)" if modern else f"assert(not {var}.modernFrame or not {var}.modernFrame.outer[1].shown)"))

TRACK="visualExtra.SetTexCoord=function(s,...) s.coords={...} end; "

for modern in (True,False):
 style='modern' if modern else 'classic'
 test('Manual item icons inherit '+style+' without effects',BASE+TRACK+"local item=put(manual('food')); B.db.iconStyle='modern'; refresh(); B.db.iconStyle='"+style+"'; refresh(); local b=assert(icon('food')); "+assertions('b',modern)+"; assert(b.action.itemID==item.id and b.attrs.type1=='item')")
 test('Queue icons inherit '+style+' without effects',TRACK+"local B=BuffTap; B.db.buffQueue=true; B.db.iconStyle='modern'; refresh(); B.db.iconStyle='"+style+"'; refresh(); local b=assert(B.queueButtons[1]); "+assertions('b',modern)+"; assert(b.attrs.type1=='spell')")
 test('Preview item icons inherit '+style+' without effects',TRACK+"local B=BuffTap; B.db.iconStyle='modern'; B:Options(); B.options.selectTab(8); B:SetAppearanceView('buff'); B.db.iconStyle='"+style+"'; B:UpdateOptionsPreviews(); local p=B.optionsPreviews.buff; for _,b in ipairs(p.manualSamples) do "+assertions('b',modern)+" end")
