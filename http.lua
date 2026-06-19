-- http.lua
local json = require("json")

-- os.sleep only exists in OpenOS, not in plain Lua (e.g. under busted).
local function sleep(seconds)
  if os.sleep then
    os.sleep(seconds)
  end
end

local HttpClient = {}
HttpClient.__index = HttpClient

local http = {}

function http.new(internet_component, base_url, api_token)
  local self = setmetatable({}, HttpClient)
  self.internet = internet_component
  self.base_url = base_url
  self.api_token = api_token
  return self
end

function HttpClient:read_all(handle)
  local code
  for attempt = 1, 40 do
    local ok
    ok, code = pcall(handle.response, handle)
    if ok and code ~= nil then
      break
    end
    sleep(0.25)
  end

  -- A nil/empty chunk doesn't reliably mean end-of-stream on the real OC
  -- Internet Card (confirmed via http_debug.lua: a still-arriving response
  -- can read back nil on the first attempt). Treat nil/"" as "not ready
  -- yet" and keep retrying for a couple seconds before giving up.
  local chunks = {}
  local stall_attempts = 0
  while stall_attempts < 10 do
    local ok, chunk = pcall(handle)
    if not ok then
      break
    elseif chunk == nil or chunk == "" then
      stall_attempts = stall_attempts + 1
      sleep(0.2)
    else
      stall_attempts = 0
      table.insert(chunks, chunk)
    end
  end

  return code, table.concat(chunks)
end

function HttpClient:request(method, path, body)
  local headers = { ["Authorization"] = "Bearer " .. self.api_token }
  local encoded_body = nil
  if body ~= nil then
    encoded_body = json.encode(body)
    headers["Content-Type"] = "application/json"
  end

  local handle = self.internet.request(self.base_url .. path, encoded_body, headers)
  local code, raw_body = self:read_all(handle)

  if code == nil then
    return false, "no response from server (connection timed out)"
  end

  if code < 200 or code >= 300 then
    return false, "HTTP " .. tostring(code) .. ": " .. raw_body
  end

  local ok, decoded = pcall(json.decode, raw_body)
  if not ok or decoded == nil then
    return false, "invalid JSON response: " .. raw_body
  end
  return true, decoded
end

function HttpClient:get_json(path)
  return self:request("GET", path, nil)
end

function HttpClient:post_json(path, body)
  return self:request("POST", path, body)
end

return http
