local archiver = require("archiver")
local cmd = require("cmd")
local http = require("http")

-- TODO: move it to utilites
local function find_tool(registry, name)
  for _, tool in ipairs(registry) do
    if tool.name == name then
      return tool, type(tool)
    end
  end
  return nil, nil
end

-- TODO: return os and arch
local function get_os_arch()
  return "linux", "x64"
end

local function install_tool(tool, version, install_path)
  if tool.source.id:match("^pkg:github/") then
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
      error("対応するOS/Archのassetが見つかりません")
    end


    -- pkg:github/owner/repo@version
    local owner, repo = tool.source.id:match("^pkg:github/([^/]+)/([^@]+)@")
    local asset_url = "https://github.com/" .. owner .. "/" .. repo .. "/download/" .. version .. "/" .. asset.file


    local bin_path = install_path .. "/" .. asset.bin
    print("Downloading into " .. bin_path)
    local asset_dest_path = "/tmp/" .. asset_url
    local err = http.download_file({ url = asset_url }, asset_dest_path)
    if err ~= nil then
      error("registry download failed: " .. err)
    end

    local err = archiver.decompress(install_path, asset_dest_path)
    if err ~= nil then
      error("extraction failed: " .. err)
    end

    return {}
  else
    -- npm等のデフォルトインストール
    local npm_cmd = "npm install " .. tool.name .. "@" .. version .. " --no-package-lock --no-save --silent"
    local result = cmd.exec(npm_cmd, { cwd = install_path })
    if result.code ~= 0 then
      error("npm install failed: " .. result.stderr)
    end
    return {}
  end
end

function PLUGIN:BackendInstall(ctx)
  local tool, _ = find_tool(PLUGIN.registry, ctx.tool)
  local version = ctx.version
  local install_path = ctx.install_path

  if not tool or not tool.source or not tool.source.id then
    error("Tool or tool.source.id not found")
  end

  install_tool(tool, version, install_path)
end
