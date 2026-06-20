-- ae2.lua
-- NOTE: method/field names below (getItemsInNetwork, getFluidsInNetwork, getCraftables,
-- getItemStack, getFluid, .size vs .amount) are a placeholder mapping for the AE2
-- OpenComputers integration. Verify the real API in-game (see README "In-game
-- verification") before relying on this in production, and update this module +
-- its spec together if they differ.
--
-- getCraftables(filter)'s `fluid` filter does not reliably split items from
-- fluids: a craftable's getItemStack()/getFluid() either returns `false` or
-- the method doesn't exist at all (call error) when the craftable is the
-- other kind. Callers must pcall both and check the return type rather than
-- assume either based on which filter was used.
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

local function describe_craftable(craftable)
  local ok1, stack = pcall(craftable.getItemStack)
  if ok1 and type(stack) == "table" then
    return "item", stack
  end
  local ok2, fluid = pcall(craftable.getFluid)
  if ok2 and type(fluid) == "table" then
    return "fluid", fluid
  end
  return nil, nil
end

function ae2.read_craftables(ae2_component)
  local result = {}

  for _, craftable in ipairs(ae2_component.getCraftables({})) do
    local kind, info = describe_craftable(craftable)
    if kind ~= nil then
      table.insert(result, { kind = kind, name = info.name, label = info.label })
    end
  end

  return result
end

local function find_craftable(ae2_component, kind, name)
  for _, craftable in ipairs(ae2_component.getCraftables({})) do
    local found_kind, info = describe_craftable(craftable)
    if found_kind == kind and info.name == name then
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
