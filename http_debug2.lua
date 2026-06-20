-- http_debug2.lua
-- Exercises the real, currently-deployed http.lua module (not a standalone
-- reimplementation) against /healthz, so we can tell whether http.lua's
-- retry logic actually works on real hardware or whether the bug is
-- elsewhere (config, the dashboard route, etc).
-- Usage:
--   wget -f "https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/http_debug2.lua?v=1" /home/client/http_debug2.lua
--   cd /home/client && lua http_debug2.lua

local component = require("component")
local config = require("config")
local http = require("http")

local client = http.new(component.internet, config.dashboard_url, config.api_token)

print("calling client:get_json('/healthz') ...")
local ok, result = client:get_json("/healthz")
print("ok=" .. tostring(ok))
print("result=" .. tostring(result))
if type(result) == "table" then
  for k, v in pairs(result) do
    print("  " .. tostring(k) .. " = " .. tostring(v))
  end
end
