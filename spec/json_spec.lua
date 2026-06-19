-- spec/json_spec.lua
local json = require("json")

describe("json", function()
  it("encodes a table to a JSON object", function()
    local result = json.encode({ a = 1, b = "x" })
    assert.is_true(result == '{"a":1,"b":"x"}' or result == '{"b":"x","a":1}')
  end)

  it("encodes an array as a JSON array", function()
    assert.are.equal("[1,2,3]", json.encode({ 1, 2, 3 }))
  end)

  it("decodes a JSON object into a table", function()
    local result = json.decode('{"a":1,"b":"x"}')
    assert.are.equal(1, result.a)
    assert.are.equal("x", result.b)
  end)

  it("decodes a JSON array into a sequential table", function()
    local result = json.decode("[1,2,3]")
    assert.are.equal(1, result[1])
    assert.are.equal(3, result[3])
  end)

  it("round-trips nested structures", function()
    local original = { items = { { name = "a", count = 1 }, { name = "b", count = 2 } } }
    local round_tripped = json.decode(json.encode(original))
    assert.are.equal("a", round_tripped.items[1].name)
    assert.are.equal(2, round_tripped.items[2].count)
  end)
end)
