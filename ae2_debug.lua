-- ae2_debug.lua
-- Dumps real getCraftables() entries: what getItemStack()/getFluid() return
-- (type + value), so we can see exactly why ae2.lua's boolean-index guard
-- still isn't catching the real shape.
-- Usage:
--   wget -f "https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/ae2_debug.lua?v=1" /home/client/ae2_debug.lua
--   cd /home/client && lua ae2_debug.lua

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

local ok, craftables = pcall(ae2_component.getCraftables, {})
print("getCraftables({}) call: ok=" .. tostring(ok))
if not ok then
  print("error: " .. tostring(craftables))
  return
end
print("type=" .. type(craftables) .. " count=" .. tostring(craftables and #craftables))

for i, craftable in ipairs(craftables) do
  if i > 5 then
    print("... (truncated after 5)")
    break
  end
  print("== craftable " .. i .. " ==")
  print("  craftable type: " .. type(craftable))

  local ok1, stack = pcall(craftable.getItemStack)
  print(string.format("  getItemStack(): ok=%s type=%s value=%s", tostring(ok1), type(stack), tostring(stack)))
  if type(stack) == "table" then
    for k, v in pairs(stack) do
      print("    stack." .. tostring(k) .. " = " .. tostring(v))
    end
  end

  local ok2, fluid = pcall(craftable.getFluid)
  print(string.format("  getFluid(): ok=%s type=%s value=%s", tostring(ok2), type(fluid), tostring(fluid)))
  if type(fluid) == "table" then
    for k, v in pairs(fluid) do
      print("    fluid." .. tostring(k) .. " = " .. tostring(v))
    end
  end
end
