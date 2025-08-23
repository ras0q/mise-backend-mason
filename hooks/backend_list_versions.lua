local archiver = require("archiver")
local cmd = require("cmd")
local file = require("file")
local json = require("json")
local http = require("http")

local function download_registry()
  local REGISTRY_ZIP_URL = "https://github.com/mason-org/mason-registry/releases/latest/download/registry.json.zip"
  local REGISTRY_ZIP_PATH = "/tmp/registry.json.zip"
  local REGISTRY_CACHE_DIR = "~/.cache/mise-backend-mason"
  local REGISTRY_JSON_PATH = REGISTRY_CACHE_DIR .. "/registry.json"


  print("Fetching mason registry...")
  local err = http.download_file({ url = REGISTRY_ZIP_URL }, REGISTRY_ZIP_PATH)
  if err ~= nil then
    error("registry download failed: " .. err)
  end

  local err = archiver.decompress(REGISTRY_CACHE_DIR, REGISTRY_ZIP_PATH)
  if err ~= nil then
    error("extraction failed: " .. err)
  end

  local registry_json = file.read(REGISTRY_JSON_PATH)
  if not registry_json then
    error("registry read failed: " .. REGISTRY_JSON_PATH)
  end

  local success, registry = pcall(json.decode, registry_json)
  if not success then
    error("invalid registry JSON: " .. REGISTRY_JSON_PATH)
  end

  return registry
end

local function find_tool(registry, name)
  for _, tool in ipairs(registry) do
    if tool.name == name then
      return tool, type(tool)
    end
  end

  return nil, nil
end

function PLUGIN:BackendListVersions(ctx)
  local registry = download_registry()
  PLUGIN.registry = registry
  local tool, _ = find_tool(registry, ctx.tool)

  local version = nil
  if tool and tool.source and tool.source.id then
    local at_pos = string.find(tool.source.id, "@", 1, true)
    if at_pos then
      version = string.sub(tool.source.id, at_pos + 1)
    end
  end

  return { versions = { version } }
end
