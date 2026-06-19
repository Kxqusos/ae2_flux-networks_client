-- main.lua
local component = require("component")
local computer = require("computer")
local event = require("event")

local config = require("config")
local http = require("http")
local flux = require("flux")
local ae2 = require("ae2")

local function find_component(component_type)
  local address = component.list(component_type)()
  if address == nil then
    return nil
  end
  return component.proxy(address)
end

local function push_flux(client, flux_component)
  local reading = flux.read(flux_component)
  local ok, result = client:post_json("/api/client/flux", reading)
  if not ok then
    print("flux push failed: " .. tostring(result))
  end
end

local function push_inventory(client, ae2_component)
  local payload = {
    items = ae2.read_items(ae2_component),
    craftables = ae2.read_craftables(ae2_component),
  }
  local ok, result = client:post_json("/api/client/inventory", payload)
  if not ok then
    print("inventory push failed: " .. tostring(result))
  end
end

local function process_orders(client, ae2_component)
  local ok, result = client:get_json("/api/client/orders/pending")
  if not ok then
    print("fetching pending orders failed: " .. tostring(result))
    return
  end

  for _, order in ipairs(result.orders) do
    local craft_ok, message = ae2.request_craft(ae2_component, order.kind, order.item, order.amount)
    local status_payload
    if craft_ok then
      status_payload = { status = "requested" }
    else
      status_payload = { status = "failed", message = message }
    end
    local report_ok, report_result = client:post_json(
      "/api/client/orders/" .. order.id .. "/result",
      status_payload
    )
    if not report_ok then
      print("reporting order " .. order.id .. " failed: " .. tostring(report_result))
    end
  end
end

local function run_once(client, flux_component, ae2_component)
  push_flux(client, flux_component)
  push_inventory(client, ae2_component)
  process_orders(client, ae2_component)
end

local function main()
  local internet_component = component.internet
  local flux_component = find_component("flux_controller") -- TBD exact type name
  local ae2_component = find_component("me_controller") or find_component("me_interface")

  if internet_component == nil then
    error("no internet card found")
  end
  if flux_component == nil then
    error("no Flux Networks component found")
  end
  if ae2_component == nil then
    error("no AE2 component found")
  end

  local client = http.new(internet_component, config.dashboard_url, config.api_token)

  while true do
    local ok, err = pcall(run_once, client, flux_component, ae2_component)
    if not ok then
      print("loop iteration failed: " .. tostring(err))
    end
    os.sleep(config.poll_interval)
  end
end

main()
