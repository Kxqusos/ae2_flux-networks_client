-- flux.lua
-- NOTE: method names (getInput/getOutput/getEnergyStored/getMaxEnergyStored) are a
-- placeholder mapping. Verify the real method names exposed by the Flux Networks
-- OpenComputers integration in-game (see README "In-game verification") before
-- relying on this in production, and update this module if they differ.
local flux = {}

function flux.read(flux_component)
  local capacity = nil
  if flux_component.getMaxEnergyStored ~= nil then
    capacity = flux_component.getMaxEnergyStored()
  end

  return {
    energy_in = flux_component.getInput(),
    energy_out = flux_component.getOutput(),
    buffer = flux_component.getEnergyStored(),
    capacity = capacity,
  }
end

return flux
