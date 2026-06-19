-- http.lua
local json = require("json")

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
    os.sleep(0.25)
  end

  local chunks = {}
  local empty_attempts = 0
  while empty_attempts < 10 do
    local ok, chunk = pcall(handle)
    if not ok or chunk == nil then
      break
    elseif chunk == "" then
      empty_attempts = empty_attempts + 1
      os.sleep(0.2)
    else
      empty_attempts = 0
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
