local archiver = require("archiver")
local cmd = require("cmd")
local json = require("json")
local http = require("http")

local M = {}

function M.download_registry()
  local REGISTRY_ZIP_URL = "https://github.com/mason-org/mason-registry/releases/latest/download/registry.json.zip"
  local REGISTRY_ZIP_PATH = "/tmp/registry.json.zip"
  local REGISTRY_CACHE_DIR = os.getenv("HOME") .. "/.cache/mise-backend-mason"
  local REGISTRY_JSON_PATH = REGISTRY_CACHE_DIR .. "/registry.json"

  local registry_json = io.open(REGISTRY_JSON_PATH, "r")
  if not registry_json then
    local err = http.download_file({
      url = REGISTRY_ZIP_URL,
      headers = { ["User-Agent"] = "mise-plugin" },
    }, REGISTRY_ZIP_PATH)
    if err ~= nil then
      error("registry download failed: " .. err)
    end

    err = archiver.decompress(REGISTRY_ZIP_PATH, REGISTRY_CACHE_DIR)
    if err ~= nil then
      error("extraction failed: " .. err)
    end

    registry_json = io.open(REGISTRY_JSON_PATH, "r")
    if not registry_json then
      error("registry read failed: " .. REGISTRY_JSON_PATH)
    end
  end

  local success, registry = pcall(json.decode, registry_json:read("*a"))
  if not success then
    error("invalid registry JSON: " .. REGISTRY_JSON_PATH)
  end

  registry_json:close()

  return registry
end

function M.find_tool(registry, name)
  for _, tool in ipairs(registry) do
    if tool.name == name then
      return tool, type(tool)
    end
  end

  return nil, nil
end

-- TODO: return correct os and arch
local function get_os_arch()
  return "linux", "x64"
end

-- replace {{ version }} into v1.2.3
-- replace {{ version | strip_prefix "v" }} into 1.2.3
local function parse_template(str, version)
  str = str:gsub("{{%s*version%s*}}", version)
  str = str:gsub("{{%s*version%s*|%s*strip_prefix%s*\"v\"%s*}}", function()
    return version:gsub("^v", "")
  end)
  return str
end

function M.install_tool(tool, version, install_path)
  -- format: pkg:github/owner/repo@version
  local owner, repo, supported_version = tool.source.id:match("^pkg:github/([^/]+)/([^@]+)@(.+)")
  if owner and repo and supported_version then
    local os, arch = get_os_arch()
    local asset
    if tool.source.asset and type(tool.source.asset) == "table" then
      for _, a in ipairs(tool.source.asset) do
        if a.target == os .. "_" .. arch then
          asset = a
          break
        end
      end
    end
    if not asset or not asset.file then
      error("not found corresponding OS/Arch")
    end

    local filename = parse_template(asset.file, version)

    local asset_url = "https://github.com/" ..
        owner .. "/" .. repo ..
        "/releases/download/" .. version ..
        "/" .. filename

    local asset_dest_path = "/tmp/mise-backend-mason-" .. filename
    local err = http.download_file({
      url = asset_url,
      headers = { ["User-Agent"] = "mise-plugin" },
    }, asset_dest_path)
    if err ~= nil then
      error("registry download failed: " .. err)
    end

    err = archiver.decompress(asset_dest_path, install_path)
    if err ~= nil then
      error("extraction failed: " .. err)
    end

    return {}
  else
    local npm_cmd = "npm install " .. tool.name .. "@" .. version .. " --no-package-lock --no-save --silent"
    local result = cmd.exec(npm_cmd, { cwd = install_path })
    if result.code ~= 0 then
      error("npm install failed: " .. result.stderr)
    end
    return {}
  end
end

return M
