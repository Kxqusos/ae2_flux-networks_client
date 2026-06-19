-- ae2.lua
-- NOTE: method/field names below (getItemsInNetwork, getFluidsInNetwork, getCraftables,
-- getItemStack, getFluid, .size vs .amount) are a placeholder mapping for the AE2
-- OpenComputers integration. Verify the real API in-game (see README "In-game
-- verification") before relying on this in production, and update this module +
-- its spec together if they differ.
local ae2 = {}

function ae2.read_items(ae2_component)
  local result = {}

  for _, item in ipairs(ae2_component.getItemsInNetwork()) do
    table.insert(result, {
      kind = "item",
      name = item.name,
      label = item.label,
      count = item.size,
    })
  end

  for _, fluid in ipairs(ae2_component.getFluidsInNetwork()) do
    table.insert(result, {
      kind = "fluid",
      name = fluid.name,
      label = fluid.label,
      count = fluid.amount,
    })
  end

  return result
end

function ae2.read_craftables(ae2_component)
  local result = {}

  for _, craftable in ipairs(ae2_component.getCraftables({})) do
    local stack = craftable.getItemStack()
    table.insert(result, { kind = "item", name = stack.name, label = stack.label })
  end

  for _, craftable in ipairs(ae2_component.getCraftables({ fluid = true })) do
    local fluid = craftable.getFluid()
    table.insert(result, { kind = "fluid", name = fluid.name, label = fluid.label })
  end

  return result
end

local function find_craftable(ae2_component, kind, name)
  local filter = (kind == "fluid") and { fluid = true } or {}
  for _, craftable in ipairs(ae2_component.getCraftables(filter)) do
    local matches
    if kind == "fluid" then
      matches = craftable.getFluid().name == name
    else
      matches = craftable.getItemStack().name == name
    end
    if matches then
      return craftable
    end
  end
  return nil
end

function ae2.request_craft(ae2_component, kind, name, amount)
  local craftable = find_craftable(ae2_component, kind, name)
  if craftable == nil then
    return false, "no craftable found for " .. kind .. " " .. name
  end

  local ok, err = pcall(craftable.request, amount)
  if not ok then
    return false, "craft request failed: " .. tostring(err)
  end
  return true, nil
end

return ae2
