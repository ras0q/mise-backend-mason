# mise-backend-mason

mason.nvim (as a language servers registry) backend for mise

## Getting started

```sh
# Install the plugin
mise plugin install mason https://github.com/ras0q/mise-backend-mason

# List available versions
mise ls-remote mason:gopls

# Install a specific version
mise install mason:gopls@v0.20.0

# Use in a project
mise use mason:gopls@latest

# Execute the tool
mise exec -- gopls --help
```

You can see supported language servers in [mason-org/mason-registry](https://github.com/mason-org/mason-registry).
