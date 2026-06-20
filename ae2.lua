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

-- AE2 component calls cross into the mod's Java implementation; a failure
-- there (e.g. a malformed stack in the network) surfaces as a bare error
-- string with no file:line info, unlike a normal Lua error. Treat any such
-- failure as "nothing to report" rather than crashing the whole poll loop.
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    print("AE2 call failed: " .. tostring(result))
    return {}
  end
  return result or {}
end

function ae2.read_items(ae2_component)
  local result = {}

  for _, item in ipairs(safe_call(ae2_component.getItemsInNetwork)) do
    local ok, name, label, count = pcall(function() return item.name, item.label, item.size end)
    if ok then
      table.insert(result, { kind = "item", name = name, label = label, count = count })
    end
  end

  for _, fluid in ipairs(safe_call(ae2_component.getFluidsInNetwork)) do
    local ok, name, label, count = pcall(function() return fluid.name, fluid.label, fluid.amount end)
    if ok then
      table.insert(result, { kind = "fluid", name = name, label = label, count = count })
    end
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

  for _, craftable in ipairs(safe_call(ae2_component.getCraftables, {})) do
    local kind, info = describe_craftable(craftable)
    if kind ~= nil then
      table.insert(result, { kind = kind, name = info.name, label = info.label })
    end
  end

  return result
end

local function find_craftable(ae2_component, kind, name)
  for _, craftable in ipairs(safe_call(ae2_component.getCraftables, {})) do
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
