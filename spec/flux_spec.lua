-- spec/flux_spec.lua
local flux = require("flux")

describe("flux.read", function()
  it("maps the component's fields into the dashboard payload shape", function()
    local mock_component = {
      getInput = function() return 100 end,
      getOutput = function() return 80 end,
      getEnergyStored = function() return 5000 end,
      getMaxEnergyStored = function() return 10000 end,
    }

    local result = flux.read(mock_component)

    assert.are.equal(100, result.energy_in)
    assert.are.equal(80, result.energy_out)
    assert.are.equal(5000, result.buffer)
    assert.are.equal(10000, result.capacity)
  end)

  it("returns nil capacity when getMaxEnergyStored is unavailable", function()
    local mock_component = {
      getInput = function() return 1 end,
      getOutput = function() return 2 end,
      getEnergyStored = function() return 3 end,
      getMaxEnergyStored = nil,
    }

    local result = flux.read(mock_component)

    assert.is_nil(result.capacity)
  end)
end)
