-- json.lua
local json = {}

local function escape_str(s)
  local out = s:gsub('[%c"\\]', function(c)
    if c == '"' then return '\\"' end
    if c == '\\' then return '\\\\' end
    if c == '\n' then return '\\n' end
    if c == '\t' then return '\\t' end
    return string.format("\\u%04x", string.byte(c))
  end)
  return out
end

local function is_array(t)
  local count = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then return false end
    count = count + 1
  end
  for i = 1, count do
    if t[i] == nil then return false end
  end
  return true
end

local encode_value

local function encode_array(t)
  local parts = {}
  for _, v in ipairs(t) do
    table.insert(parts, encode_value(v))
  end
  return "[" .. table.concat(parts, ",") .. "]"
end

local function encode_object(t)
  local parts = {}
  for k, v in pairs(t) do
    table.insert(parts, '"' .. escape_str(tostring(k)) .. '":' .. encode_value(v))
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

encode_value = function(v)
  local t = type(v)
  if v == nil then
    return "null"
  elseif t == "boolean" then
    return tostring(v)
  elseif t == "number" then
    return tostring(v)
  elseif t == "string" then
    return '"' .. escape_str(v) .. '"'
  elseif t == "table" then
    if is_array(v) then
      return encode_array(v)
    end
    return encode_object(v)
  end
  error("cannot encode value of type " .. t)
end

function json.encode(value)
  return encode_value(value)
end

-- Minimal recursive-descent JSON parser.
local function skip_whitespace(s, i)
  while i <= #s and s:sub(i, i):match("%s") do
    i = i + 1
  end
  return i
end

local parse_value

local function parse_string(s, i)
  i = i + 1 -- skip opening quote
  local start = i
  local out = {}
  while s:sub(i, i) ~= '"' do
    local c = s:sub(i, i)
    if c == "\\" then
      local next_c = s:sub(i + 1, i + 1)
      local map = { n = "\n", t = "\t", ['"'] = '"', ["\\"] = "\\" }
      table.insert(out, map[next_c] or next_c)
      i = i + 2
    else
      table.insert(out, c)
      i = i + 1
    end
  end
  return table.concat(out), i + 1
end

local function parse_number(s, i)
  local start = i
  while i <= #s and s:sub(i, i):match("[%d%.%-eE+]") do
    i = i + 1
  end
  return tonumber(s:sub(start, i - 1)), i
end

local function parse_array(s, i)
  i = i + 1 -- skip [
  local result = {}
  i = skip_whitespace(s, i)
  if s:sub(i, i) == "]" then
    return result, i + 1
  end
  while true do
    local value
    value, i = parse_value(s, i)
    table.insert(result, value)
    i = skip_whitespace(s, i)
    local c = s:sub(i, i)
    if c == "," then
      i = i + 1
      i = skip_whitespace(s, i)
    elseif c == "]" then
      return result, i + 1
    else
      error("expected , or ] in array at position " .. i)
    end
  end
end

local function parse_object(s, i)
  i = i + 1 -- skip {
  local result = {}
  i = skip_whitespace(s, i)
  if s:sub(i, i) == "}" then
    return result, i + 1
  end
  while true do
    i = skip_whitespace(s, i)
    local key
    key, i = parse_string(s, i)
    i = skip_whitespace(s, i)
    i = i + 1 -- skip :
    i = skip_whitespace(s, i)
    local value
    value, i = parse_value(s, i)
    result[key] = value
    i = skip_whitespace(s, i)
    local c = s:sub(i, i)
    if c == "," then
      i = i + 1
    elseif c == "}" then
      return result, i + 1
    else
      error("expected , or } in object at position " .. i)
    end
  end
end

parse_value = function(s, i)
  i = skip_whitespace(s, i)
  local c = s:sub(i, i)
  if c == "{" then
    return parse_object(s, i)
  elseif c == "[" then
    return parse_array(s, i)
  elseif c == '"' then
    return parse_string(s, i)
  elseif s:sub(i, i + 3) == "true" then
    return true, i + 4
  elseif s:sub(i, i + 4) == "false" then
    return false, i + 5
  elseif s:sub(i, i + 3) == "null" then
    return nil, i + 4
  else
    return parse_number(s, i)
  end
end

function json.decode(str)
  local value, _ = parse_value(str, 1)
  return value
end

return json
