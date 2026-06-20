-- http_debug3.lua
-- Very verbose, raw diagnostic: prints every single read attempt's
-- type/value/length, tries both bare-call and handle.read(n) forms, and
-- only checks response() at the very end. Use this when http_debug2.lua
-- (which uses the real http.lua module) still reports "invalid JSON
-- response" - this tells us exactly what the Internet Card is giving us.
-- Usage:
--   wget -f "https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/http_debug3.lua?v=1" /home/client/http_debug3.lua
--   cd /home/client && lua http_debug3.lua

local component = require("component")
local config = require("config")

local handle = component.internet.request(
  config.dashboard_url .. "/healthz",
  nil,
  { ["Authorization"] = "Bearer " .. config.api_token }
)

print("handle type: " .. type(handle))

print("== bare call handle() x30, 0.2s apart ==")
for attempt = 1, 30 do
  local ok, chunk = pcall(handle)
  if ok then
    print(string.format("attempt %d: type=%s len=%s repr=%q", attempt, type(chunk), tostring(chunk and #chunk or "nil"), tostring(chunk)))
  else
    print(string.format("attempt %d: pcall error: %s", attempt, tostring(chunk)))
  end
  os.sleep(0.2)
end

print("== handle.read(8192) x10, 0.2s apart ==")
for attempt = 1, 10 do
  local ok, chunk = pcall(handle.read, handle, 8192)
  if ok then
    print(string.format("attempt %d: type=%s len=%s repr=%q", attempt, type(chunk), tostring(chunk and #chunk or "nil"), tostring(chunk)))
  else
    print(string.format("attempt %d: pcall error: %s", attempt, tostring(chunk)))
  end
  os.sleep(0.2)
end

print("== final handle.response() ==")
local ok, code, message, headers = pcall(handle.response, handle)
print("ok=" .. tostring(ok) .. " code=" .. tostring(code) .. " message=" .. tostring(message))
if type(headers) == "table" then
  for k, v in pairs(headers) do
    print("  header " .. tostring(k) .. " = " .. tostring(v))
  end
end
