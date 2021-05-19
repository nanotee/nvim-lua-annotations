(You should probably check [lua-dev.nvim](https://github.com/folke/lua-dev.nvim) out instead)

# nvim-lua-annotations

A quick and dirty script to generate EmmyLua annotations for Neovim functions/APIs. WIP.

## Usage

```lua
lua require('nvim-lua-annotations').write_to_file('/path/to/annotations/dir/file.lua')
```

Use with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) and [lua-language-server](https://github.com/sumneko/lua-language-server):

```lua
require('lspconfig').sumneko_lua.setup {
    settings = {
        Lua = {
            workspace = {
                library = {
                    [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                    ['/path/to/annotations/dir'] = true,
                }
            }
        }
    }
}
```
