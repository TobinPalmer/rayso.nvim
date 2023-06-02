local M = {}

---@class plug_opts
---@field background boolean
---@field dark_mode boolean
---@field logging_path string
---@field logging_file string
---@field logging_enabled boolean
---@field padding 16 | 32 | 64 | 128 | number
---@field theme theme
---@field title string

---@alias theme  "candy" | "breeze" | "crimson"| "falcon" | "meadow" | "midnight" | "raindrop" | "sunset"
---@alias open_cmd 'firefox' | 'chromium' | string

---@class config
---@field base_url string
---@field open_cmd open_cmd
---@field options plug_opts

---@type config
M.config = {
  base_url = 'https://ray.so/',
  open_cmd = 'firefox',
  options = {
    background = true,
    dark_mode = true,
    logging_path = '',
    logging_file = 'rayso',
    logging_enabled = false,
    padding = 32,
    theme = 'crimson',
    title = vim.fn.expand '%' or 'Untitled',
  },
}

-- setup is the initialization function for the carbon plugin
---@param params config
M.setup = function(params)
  M.config = vim.tbl_deep_extend('force', {}, M.config, params or {})
  require('lib.create').create_commands()
end

return M
