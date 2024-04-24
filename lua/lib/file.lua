local M = {}
local rayso = require 'rayso'
---@param file string
---@return boolean
M.file_exists = function(file)
  local f = io.open(file, 'rb')
  if f then
    f:close()
  end
  return f ~= nil
end

---@param file string
M.lines_from = function(file)
  if not M.file_exists(file) then
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
M.create_file = function(path, name)
  local file = path .. name .. '.md'
  vim.notify('FILE' .. file, vim.log.levels.INFO)

  if M.file_exists(file) then
    -- return error 'File already exists'
    return vim.notify('File already exists', vim.log.levels.INFO)
  end

  -- Create directory if it doesn't exist
  local success, err = os.execute('mkdir -p "' .. path .. '"')
  if not success then
    return vim.notify('Failed to create directory: ' .. err, vim.log.levels.ERROR)
    -- return error('Failed to create directory: ' .. err)
  end

  local f, error = io.open(file, 'w')
  if f then
    f:close()
  else
    if error then
      return vim.notify('Failed to create file: ' .. error, vim.log.levels.ERROR)
      -- return error('Failed to create file:', error)
    end
    return "Something went very wrong, couldn't create the file"
  end
end

---@param url string
---@param code string
---@param lang string
M.log = function(url, code, lang)
  if rayso.config.options.logging_enabled == false then
    return
  end

  local file = rayso.config.options.logging_path .. rayso.config.options.logging_file .. '.md'
  if M.file_exists(file) then
    local f = io.open(file, 'a')
    --- Check if the code is longer than 5 lines, then add ...
    if code:match '\n' then
      local lines = {}
      for line in code:gmatch '[^\r\n]+' do
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
    local file_, _ = f:write(code_block)
    if file_ then
      f:close()
    else
      return
    end
  else
    vim.notify("Config file doesn't exist, creating it", vim.log.levels.INFO)
    M.create_file(rayso.config.options.logging_path, rayso.config.options.logging_file)
    if rayso.config == nil then
      return
    end
    M.create_file(rayso.config.options.logging_path, rayso.config.options.logging_file)
  end
end

return M
