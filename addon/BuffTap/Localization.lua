-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
local _,B=...
B.Locales={}
local locale="enUS"
if type(GetLocale)=="function" then
  local ok,value=pcall(GetLocale)
  if ok and type(value)=="string" then locale=value end
end
if locale=="esMX" then locale="esES" end
B.locale=locale
-- Lookup occurs only when displaying text; IDs, settings and engine states stay unchanged.
function B:Text(key,...)
  if type(key)~="string" then return key end
  local messages=self.Locales[self.locale]
  local text=messages and messages[key] or key
  if select("#",...)==0 then return text end
  local ok,value=pcall(string.format,text,...)
  if ok then return value end
  ok,value=pcall(string.format,key,...)
  return ok and value or key
end
