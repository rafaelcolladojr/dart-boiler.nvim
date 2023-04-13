local M = {}

M.boil = function ()
  -- local language = vim.bo.filetype;
  -- if (language ~= 'dart') then
  --   return
  -- end

  -- Visual selection range
  local vstart = vim.fn.getpos("'<")[2] - 1
  local vend = vim.fn.getpos("'>")[2]

  local bufnr = vim.api.nvim_get_current_buf()

  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, vstart, vend, false)
  local fields = M._boil_process_lines(buf_lines)
  -- P(fields)
  local replacement = M._boil_boilerplate(fields)
  P(replacement)
  vim.api.nvim_buf_set_lines(bufnr, vstart, vend, false, replacement)
end

M._boil_process_lines = function (buf_lines)
  local regex_required = "^%s*(%w+)(%p?).*%s+([a-zA-Z_-]+)[,;:]*%s*$"
  local fields = {inherited={}, required={}, optional={}}
  for _, value in ipairs(buf_lines) do
    local _, _, type, scope, name = string.find(value, regex_required)
    local field = {type = type, name = name}
    if scope == "!" then
      table.insert(fields.inherited, field)
    elseif scope == "" then
      table.insert(fields.required, field)
    elseif scope == "?" then
      table.insert(fields.optional, field)
    end
  end
  return fields
end

M._boil_constructor = function (fields)
  local constructor = {
    "const __CLASS__({",
  }
  for _, field in ipairs(fields.inherited) do
    local comp = "\t" .. field.type .. "? " .. field.name .. ","
    table.insert(constructor, comp)
  end
  for _, field in ipairs(fields.required) do
    local comp = "\trequired this." .. field.name .. ","
    table.insert(constructor, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = "\tthis." .. field.name .. ","
    table.insert(constructor, comp)
  end
  if #fields.inherited then
    table.insert(constructor, "}): super(")
    for _, field in ipairs(fields.inherited) do
      local comp = "\t" .. field.name .. ": " .. field.name .. ","
      table.insert(constructor, comp)
    end
    table.insert(constructor, ");")
  else
    table.insert(constructor, "});")
  end
  return constructor
end

M._boil_boilerplate = function(fields)
  local replacement = {}
  local constructor = M._boil_constructor(fields)
  table.insert(replacement, constructor)
  return constructor
end

return M

--[[
Test Cases

String! id,
String! createUserId,
DateTime! createTime,
String firstName,
String lastName,
String? email,

--]]
