-- http_debug4.lua
-- Mirrors http.lua's exact read_all algorithm (handle.read(8192) without
-- self, stall-retry, then response() once) but with verbose per-attempt
-- printing, to see exactly where it diverges from working.
-- Usage:
--   wget -f "https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/http_debug4.lua?v=1" /home/client/http_debug4.lua
--   cd /home/client && lua http_debug4.lua

local component = require("component")
local config = require("config")

local handle = component.internet.request(
  config.dashboard_url .. "/healthz",
  nil,
  { ["Authorization"] = "Bearer " .. config.api_token }
)

print("handle.read type: " .. type(handle.read))

local chunks = {}
local stall_attempts = 0
local iteration = 0
while stall_attempts < 20 do
  iteration = iteration + 1
  local ok, chunk = pcall(handle.read, 8192)
  print(string.format(
    "iter %d: ok=%s type=%s len=%s repr=%q stall=%d",
    iteration, tostring(ok), type(chunk), tostring(chunk and #chunk or "nil"), tostring(chunk), stall_attempts
  ))
  if not ok then
    print("  -> breaking (pcall error)")
    break
  elseif chunk == nil or chunk == "" then
    stall_attempts = stall_attempts + 1
    os.sleep(0.2)
  else
    stall_attempts = 0
    table.insert(chunks, chunk)
  end
end

print("body so far: " .. table.concat(chunks))

local code
for attempt = 1, 10 do
  local ok
  ok, code = pcall(handle.response, handle)
  print(string.format("response attempt %d: ok=%s code=%s", attempt, tostring(ok), tostring(code)))
  if ok and code ~= nil then
    break
  end
  os.sleep(0.2)
end

print("FINAL: code=" .. tostring(code) .. " body=" .. table.concat(chunks))
