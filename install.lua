-- install.lua
-- One-shot installer: downloads the runtime .lua files for this client
-- from GitHub onto the local OpenComputers filesystem.
-- Usage (in an OC shell, with an Internet Card installed):
--   wget -f https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/install.lua /home/install.lua
--   install

local internet = require("internet")
local filesystem = require("filesystem")
local shell = require("shell")

local base_url = "https://raw.githubusercontent.com/Kxqusos/ae2_flux-networks_client/main/"
local files = { "json.lua", "http.lua", "flux.lua", "ae2.lua", "config.lua", "main.lua" }
local dest_dir = "/home/"

local function download(url)
  local result = {}
  local ok, response = pcall(internet.request, url)
  if not ok then
    error("request failed: " .. tostring(response))
  end
  for chunk in response do
    table.insert(result, chunk)
  end
  return table.concat(result)
end

for _, name in ipairs(files) do
  local dest = dest_dir .. name
  if filesystem.exists(dest) and name == "config.lua" then
    io.write("skipping " .. name .. " (already exists, keeping your config)\n")
  else
    io.write("downloading " .. name .. "...\n")
    local content = download(base_url .. name)
    local f = io.open(dest, "w")
    f:write(content)
    f:close()
  end
end

io.write("\nDone. Edit /home/config.lua with your dashboard_url and api_token, then run: main\n")
