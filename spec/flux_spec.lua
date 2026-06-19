-- spec/flux_spec.lua
local flux = require("flux")

describe("flux.read", function()
  it("maps getEnergyInfo's fields into the dashboard payload shape", function()
    local mock_component = {
      getEnergyInfo = function()
        return {
          totalEnergy = 0,
          energyOutput = 9453727,
          energyInput = 10091904,
          totalBuffer = 1,
        }
      end,
    }

    local result = flux.read(mock_component)

    assert.are.equal(10091904, result.energy_in)
    assert.are.equal(9453727, result.energy_out)
    assert.are.equal(1, result.buffer)
    assert.is_nil(result.capacity)
  end)
end)
