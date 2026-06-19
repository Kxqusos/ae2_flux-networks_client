-- flux.lua
-- Verified in-game (2026-06-20): the real Flux Networks OpenComputers API
-- exposes a flux_controller component with getNetworkInfo/getFluxInfo/
-- getCountInfo/getEnergyInfo, NOT the originally-placeholder getInput/
-- getOutput/getEnergyStored/getMaxEnergyStored. getEnergyInfo() returns
-- {totalEnergy, energyOutput, energyInput, totalBuffer}. None of the four
-- info methods expose a total network capacity, so `capacity` is always nil.
local flux = {}

function flux.read(flux_component)
  local energy = flux_component.getEnergyInfo()

  return {
    energy_in = energy.energyInput,
    energy_out = energy.energyOutput,
    buffer = energy.totalBuffer,
    capacity = nil,
  }
end

return flux
