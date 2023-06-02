local M = {}

-- Generates encoded query params
--- @param str string
M.query_param_encode = function(str)
  str = string.gsub(str, '\r?\n', '\r\n')
  str = string.gsub(str, '([^%w%-%.%_%~ ])', function(c)
    return string.format('%%%02X', string.byte(c))
  end)

  str = string.gsub(str, ' ', '+')
  return str
end

-- helper function to encode a k,v table into encoded query params
---@return string
M.encode_params = function(values)
  local params = {}
  for k, v in pairs(values) do
    if type(v) ~= 'string' then
      v = tostring(v)
    end
    table.insert(params, k .. '=' .. M.query_param_encode(v))
  end

  ---@type string
  local url = 'https://ray.so/#'

  ---@param v string
  for _, v in pairs(params) do
    url = url .. v .. '&'
  end

  return url
end

-- validate config param values and create the query params table
---@param code string | nil
---@return string
M.generate_query_params = function(code)
  local opts = M.config.options
  local params = {
    theme = opts.theme,
    background = opts.background,
    darkMode = opts.dark_mode,
    padding = opts.padding,
    title = opts.title,
  }

  if code ~= nil then
    params.code = require('rayso.base64').enc(code)
    params.language = vim.bo.filetype
  end

  return M.encode_params(params)
end

return M
