function PLUGIN:BackendInstall(ctx)
  local utils = require("utils")

  local registry = PLUGIN.registry
  if not registry then
    registry = utils.download_registry()
  end
  local tool, _ = utils.find_tool(registry, ctx.tool)
  local version = ctx.version
  local install_path = ctx.install_path

  if not tool or not tool.source or not tool.source.id then
    error("Tool or tool.source.id not found")
  end

  local install_resp = utils.install_tool(tool, version, ctx.tool, install_path)
  return install_resp
end
