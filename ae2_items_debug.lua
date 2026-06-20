-- ae2_items_debug.lua
-- Dumps the real shape of getItemsInNetwork()/getFluidsInNetwork() entries -
-- read_items currently assumes item.name/.label/.size and
-- fluid.name/.label/.amount, but unlike the craftable stack shape (already
-- verified), these have never been checked against the real API.
-- Usage:
--   wget -f "https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/ae2_items_debug.lua?v=1" /home/client/ae2_items_debug.lua
--   cd /home/client && lua ae2_items_debug.lua

local component = require("component")

local function safe_primary(ctype)
  local ok, proxy = pcall(function() return component[ctype] end)
  if ok then
    return proxy
  end
  return nil
end

local ae2_component = safe_primary("me_controller") or safe_primary("me_interface")
if ae2_component == nil then
  print("no AE2 component found")
  return
end

local function dump_list(label, fn)
  local ok, list = pcall(fn)
  print(label .. ": ok=" .. tostring(ok))
  if not ok then
    print("  error: " .. tostring(list))
    return
  end
  print("  type=" .. type(list) .. " count=" .. tostring(list and #list))
  for i, entry in ipairs(list) do
    if i > 3 then
      print("  ... (truncated after 3)")
      break
    end
    print("  == entry " .. i .. " == type=" .. type(entry))
    if type(entry) == "table" then
      for k, v in pairs(entry) do
        print("    " .. tostring(k) .. " = " .. tostring(v))
      end
    end
  end
end

dump_list("getItemsInNetwork()", function() return ae2_component.getItemsInNetwork() end)
dump_list("getFluidsInNetwork()", function() return ae2_component.getFluidsInNetwork() end)
