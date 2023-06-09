local M = {}
local param_util = require 'lib.params'
local rayso = require 'rayso'

-- Gets the open command from the config
M.get_open_command = function()
  -- On a mac
  if vim.fn.has 'macunix'==1 then
    return 'open -a ' .. rayso.config.open_cmd .. '.app'
  end

  if vim.fn.has 'win32'==1 then
    return 'start ' .. rayso.config.open_cmd
  end
  -- Not an mac and command is not an executable
  if vim.fn.executable(rayso.config.open_cmd) == 0 then
    return error('Could not find executable for ' .. rayso.config.open_cmd)
  end

  return M.config.open_cmd
end

-- Creates the snippet
---@param opts table
M.create_snippet = function(opts)
  local function dump(o)
    if type(o) == 'table' then
      local s = '{ '
      for k, v in pairs(o) do
        if type(k) ~= 'number' then
          k = '"' .. k .. '"'
        end
        s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
      end
      return s .. '} '
    else
      return tostring(o)
    end
  end
  -- If called via a binding
  if opts == nil then
    opts = {}
    opts.line1 = vim.fn.line 'v'
    opts.line2 = vim.fn.line '.'
    if opts.args == nil then
      opts.args = ''
    end
  end
  ---@type open_cmd | nil
  local open_cmd = M.get_open_command()
  ---@type string
  local url
  ---@type string
  local query_params
  ---@type string
  local code

  if open_cmd == nil then
    return
  end

  if opts.args ~= '' then
    query_params = param_util.generate_query_params()
    url = M.config.base_url .. '' .. opts.args .. '' .. query_params

    -- Get the whole files text as a string
    --- get the current buffer
    local whole_file = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    code = whole_file
  else
    local range = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local lines = table.concat(range, '\n', 1, #range)
    query_params = param_util.generate_query_params(lines)
    url = param_util.generate_query_params(lines)
    code = lines
  end
  require('lib.file').log(url, code, vim.bo.filetype)

  ---@type string
  local quation = nil
  if vim.fn.has 'macunix'==1 then
    quation = "'"
  elseif vim.fn.has 'win32'==1 then
    quation = '"'
  end
  local cmd = open_cmd .. ' ' .. quation .. url .. quation
  vim.fn.system(cmd)
end

--- Creates the commands for the plugin
M.create_commands = function()
  ---@param opts table
  vim.api.nvim_create_user_command('Rayso', function(opts)
    require('lib.create').create_snippet(opts)
  end, { range = '%', nargs = '?' })
end
return M
