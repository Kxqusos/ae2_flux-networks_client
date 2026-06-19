-- http_debug.lua
-- Diagnostic for the real OpenComputers internet.request async handshake.
-- Usage: edit the url/token below to match your config.lua, then:
--   wget -f https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/http_debug.lua /home/http_debug.lua
--   lua http_debug.lua

local component = require("component")
local config = require("config")

local handle = component.internet.request(
  config.dashboard_url .. "/healthz",
  nil,
  { ["Authorization"] = "Bearer " .. config.api_token }
)

print("handle created, polling response() up to 20 times...")
for attempt = 1, 20 do
  local ok, code, message = pcall(handle.response, handle)
  print(string.format("attempt %d: ok=%s code=%s message=%s", attempt, tostring(ok), tostring(code), tostring(message)))
  if ok and code ~= nil then
    break
  end
  os.sleep(0.5)
end

print("reading body chunks...")
local chunks = {}
while true do
  local ok, chunk = pcall(handle)
  if not ok then
    print("read error: " .. tostring(chunk))
    break
  end
  if chunk == nil then
    break
  end
  table.insert(chunks, chunk)
end
print("body: " .. table.concat(chunks))

local code, message = handle.response()
print("final response(): code=" .. tostring(code) .. " message=" .. tostring(message))
