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
    title = 'Untitled',
  },
}

---@param file string
---@return boolean
local function file_exists(file)
  local f = io.open(file, 'rb')
  if f then
    f:close()
  end
  return f ~= nil
end

---@param file string
local function lines_from(file)
  if not file_exists(file) then
    return {}
  end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

---@param name string
---@param path string
local function create_file(path, name)
  local file = path .. name .. '.md'

  if file_exists(file) then
    return error('File already exists')
  end

  -- Create directory if it doesn't exist
  local success, err = os.execute('mkdir -p "' .. path .. '"')
  if not success then
    return error('Failed to create directory: ' .. err)
  end

  local f, error = io.open(file, 'w')
  if f then
    f:close()
  else
    if error then
      return error('Failed to create file:', error)
    end
    return "Something went very wrong, couldn't create the file"
  end
end

---@param url string
---@param code string
---@param lang string
local function log(url, code, lang)
  if M.config.options.logging_enabled == false then
    return
  end

  local file = M.config.options.logging_path .. M.config.options.logging_file .. '.md'
  if file_exists(file) then
    local f = io.open(file, 'a')
    --- Check if the code is longer than 5 lines, then add ...
    if code:match('\n') then
      local lines = {}
      for line in code:gmatch('[^\r\n]+') do
        table.insert(lines, line)
      end
      if #lines > 5 then
        code = ''
        for i = 1, 5 do
          code = code .. lines[i] .. '\n'
        end
        code = code .. '...'
      end
    end

    local code_block = string.format('```%s\n%s\n```\n[link](%s)\n\n', lang, code, url)

    if f == nil then
      return
    end
    local file_, success = f:write(code_block)
    if file_ then
      f:close()
    else
      print('error', success)
      return
    end
  else
    print("doesn't exist, ccreating")
    create_file(M.config.options.logging_path, M.config.options.logging_file)
  end
end

-- Generates encoded query params
--- @param str string
local function query_param_encode(str)
  str = string.gsub(str, '\r?\n', '\r\n')
  str = string.gsub(str, '([^%w%-%.%_%~ ])', function(c)
    return string.format('%%%02X', string.byte(c))
  end)

  str = string.gsub(str, ' ', '+')
  return str
end

-- helper function to encode a k,v table into encoded query params
---@return string
local function encode_params(values)
  local params = {}
  for k, v in pairs(values) do
    if type(v) ~= 'string' then
      v = tostring(v)
    end
    table.insert(params, k .. '=' .. query_param_encode(v))
  end

  ---@type string
  local url = 'https://ray.so/#'

  ---@param v string
  for _, v in pairs(params) do
    url = url .. v .. '&'
  end

  return url
end

-- https://stackoverflow.com/questions/34618946/lua-base64-encode
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function enc(data)
  return (
    (data:gsub('.', function(x)
      local r, b = '', x:byte()
      for i = 8, 1, -1 do
        r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
      end
      return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
      if #x < 6 then
        return ''
      end
      local c = 0
      for i = 1, 6 do
        c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
      end
      return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1]
  )
end

-- decoding
local function dec(data)
  data = string.gsub(data, '[^' .. b .. '=]', '')
  return (
    data
      :gsub('.', function(x)
        if x == '=' then
          return ''
        end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do
          r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
        end
        return r
      end)
      :gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then
          return ''
        end
        local c = 0
        for i = 1, 8 do
          c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
      end)
  )
end

-- validate config param values and create the query params table
---@param code string | nil
---@return string
local function generate_query_params(code)
  local opts = M.config.options
  local params = {
    theme = opts.theme,
    background = opts.background,
    darkMode = opts.dark_mode,
    padding = opts.padding,
    title = opts.title,
  }

  if code ~= nil then
    params.code = enc(code)
    params.language = vim.bo.filetype
  end

  return encode_params(params)
end

-- Gets the open command from the config
local function get_open_command()
  -- On a mac
  if vim.fn.has('macunix') then
    return 'open -a ' .. M.config.open_cmd .. '.app'
  end

  -- Not an mac and command is not an executable
  if vim.fn.executable(M.config.open_cmd) == 0 then
    return error('Could not find executable for ' .. M.config.open_cmd)
  end

  return M.config.open_cmd
end

-- Creates the snippet
---@param opts table
local function create_snippet(opts)
  ---@type open_cmd | nil
  local open_cmd = get_open_command()
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
    query_params = generate_query_params()
    url = M.config.base_url .. '' .. opts.args .. '' .. query_params

    -- Get the whole files text as a string
    --- get the current buffer
    local whole_file = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    code = whole_file
  else
    local range = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local lines = table.concat(range, '\n', 1, #range)
    query_params = generate_query_params(lines)
    url = generate_query_params(lines)
    code = lines
  end
  print(code)
  log(url, code, vim.bo.filetype)

  ---@type string
  local cmd = open_cmd .. ' ' .. "'" .. url .. "'"
  vim.fn.system(cmd)
end

--- Creates the commands for the plugin
local function create_commands()
  ---@param opts table
  vim.api.nvim_create_user_command('Rayso', function(opts)
    create_snippet(opts)
  end, { range = '%', nargs = '?' })
end

-- setup is the initialization function for the carbon plugin
---@param params config
M.setup = function(params)
  M.config = vim.tbl_deep_extend('force', {}, M.config, params or {})
  create_commands()
end

return M