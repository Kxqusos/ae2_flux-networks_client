-- discover.lua
-- One-shot diagnostic: lists connected components, the methods exposed by
-- the Flux Networks and AE2 components, and dumps the actual return values
-- of the Flux Networks "info" methods so we can map their real fields onto
-- flux.lua's energy_in/energy_out/buffer/capacity shape.
-- Usage (in an OC shell):
--   wget -f https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/discover.lua /home/discover.lua
--   discover

local component = require("component")

print("== connected components ==")
for address, ctype in component.list() do
  print(ctype, address)
end

local function safe_primary(ctype)
  local ok, proxy = pcall(function() return component[ctype] end)
  if ok then
    return proxy
  end
  return nil
end

local function dump_methods(label, proxy)
  if proxy == nil then
    print(label .. ": not found")
    return
  end
  print("== " .. label .. " methods ==")
  for name in pairs(component.methods(proxy.address)) do
    print(name)
  end
end

local flux = safe_primary("flux_controller")
local ae2 = safe_primary("me_controller") or safe_primary("me_interface")

dump_methods("flux_controller", flux)
dump_methods("me_controller/me_interface", ae2)

local function dump_table(t, indent)
  indent = indent or "  "
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(indent .. tostring(k) .. ":")
      dump_table(v, indent .. "  ")
    else
      print(indent .. tostring(k) .. " = " .. tostring(v))
    end
  end
end

if flux ~= nil then
  for _, method_name in ipairs({ "getNetworkInfo", "getFluxInfo", "getCountInfo", "getEnergyInfo" }) do
    local fn = flux[method_name]
    if fn ~= nil then
      print("== flux_controller." .. method_name .. "() result ==")
      local ok, result = pcall(fn)
      if not ok then
        print("  error: " .. tostring(result))
      elseif type(result) == "table" then
        dump_table(result)
      else
        print("  " .. tostring(result))
      end
    end
  end
end
