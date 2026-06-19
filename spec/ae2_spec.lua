-- spec/ae2_spec.lua
local ae2 = require("ae2")

describe("ae2.read_items", function()
  it("combines items and fluids with the correct kind tag", function()
    local mock_component = {
      getItemsInNetwork = function()
        return { { name = "minecraft:iron_ingot", label = "Iron Ingot", size = 64 } }
      end,
      getFluidsInNetwork = function()
        return { { name = "minecraft:lava", label = "Lava", amount = 8000 } }
      end,
    }

    local result = ae2.read_items(mock_component)

    assert.are.equal(2, #result)
    assert.are.equal("item", result[1].kind)
    assert.are.equal(64, result[1].count)
    assert.are.equal("fluid", result[2].kind)
    assert.are.equal(8000, result[2].count)
  end)
end)

describe("ae2.read_craftables", function()
  it("tags item and fluid craftables, using getItemStack/getFluid's false return to tell them apart", function()
    local mock_component = {
      getCraftables = function()
        return {
          {
            getItemStack = function() return { name = "minecraft:iron_ingot", label = "Iron Ingot" } end,
            getFluid = function() return false end,
          },
          {
            getItemStack = function() return false end,
            getFluid = function() return { name = "minecraft:lava", label = "Lava" } end,
          },
        }
      end,
    }

    local result = ae2.read_craftables(mock_component)

    assert.are.equal(2, #result)
    assert.are.equal("item", result[1].kind)
    assert.are.equal("minecraft:iron_ingot", result[1].name)
    assert.are.equal("fluid", result[2].kind)
    assert.are.equal("minecraft:lava", result[2].name)
  end)
end)

describe("ae2.request_craft", function()
  it("requests the matching craftable by kind and name", function()
    local requested_amount = nil
    local mock_component = {
      getCraftables = function()
        return {
          {
            getItemStack = function() return { name = "minecraft:iron_ingot", label = "Iron Ingot" } end,
            getFluid = function() return false end,
            request = function(amount) requested_amount = amount end,
          },
        }
      end,
    }

    local ok, message = ae2.request_craft(mock_component, "item", "minecraft:iron_ingot", 64)

    assert.is_true(ok)
    assert.are.equal(64, requested_amount)
  end)

  it("returns ok=false when no matching craftable exists", function()
    local mock_component = {
      getCraftables = function() return {} end,
    }

    local ok, message = ae2.request_craft(mock_component, "item", "minecraft:unknown", 1)

    assert.is_false(ok)
    assert.is_not_nil(message)
  end)
end)
