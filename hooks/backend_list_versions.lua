function PLUGIN:BackendListVersions(ctx)
  local utils = require("utils")

  local registry = utils.download_registry()
  PLUGIN.registry = registry
  local tool, _ = utils.find_tool(registry, ctx.tool)

  local version = nil
  if tool and tool.source and tool.source.id then
    local at_pos = string.find(tool.source.id, "@", 1, true)
    if at_pos then
      version = string.sub(tool.source.id, at_pos + 1)
    end
  end

  return { versions = { version } }
end
