-- discover.lua
-- One-shot diagnostic: lists connected components and the methods exposed by
-- the Flux Networks and AE2 components, to find the real method names for
-- flux.lua / ae2.lua (see their placeholder-mapping comments).
-- Usage (in an OC shell):
--   wget -f https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/discover.lua /home/discover.lua
--   discover

local component = require("component")

print("== connected components ==")
for address, ctype in component.list() do
  print(ctype, address)
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

dump_methods("flux_controller", component.flux_controller)
dump_methods("me_controller", component.me_controller)
dump_methods("me_interface", component.me_interface)
