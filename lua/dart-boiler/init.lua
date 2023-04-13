local M = {}

-- PROCESS HIGHLIGHTED LINES
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

-- BOILERPLATE CONSTRUCTOR
M._boil_constructor = function (fields, replacement)
    table.insert(replacement, "const __CLASS__({")
  for _, field in ipairs(fields.inherited) do
    local comp = "\t" .. field.type .. "? " .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.required) do
    local comp = "\trequired this." .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = "\tthis." .. field.name .. ","
    table.insert(replacement, comp)
  end
  if #fields.inherited then
    table.insert(replacement, "}): super(")
    for _, field in ipairs(fields.inherited) do
      local comp = "\t" .. field.name .. ": " .. field.name .. ","
      table.insert(replacement, comp)
    end
    table.insert(replacement, ");")
  else
    table.insert(replacement, "});")
  end
end

-- ALL FIELDS (AFTER CONSTRUCTOR)
M._boil_fields = function (fields, replacement)
  table.insert(replacement, "")
  for _, field in ipairs(fields.required) do
    local comp = "\tfinal ".. field.type .. " " .. field.name .. ";"
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = "\tfinal ".. field.type .. "? " .. field.name .. ";"
    table.insert(replacement, comp)
  end
end

-- ALL BOILERPLATE CODE
M._boil_boilerplate = function(fields, replacement)
  M._boil_constructor(fields, replacement)
  M._boil_fields(fields, replacement)
end

-- PUBLIC BOILERPLATE GENERATION COMMAND
M.boil = function ()
  -- local bufnr = vim.api.nvim_get_current_buf()
  -- if vim.bo[bufnr].filetype ~= "dart" then
  --   vim.notify("Only Dart is supported")
  -- end

  -- Visual selection range
  local vstart = vim.fn.getpos("'<")[2] - 1
  local vend = vim.fn.getpos("'>")[2]

  -- Extract lines from selection
  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, vstart, vend, false)
  local fields = M._boil_process_lines(buf_lines)

  -- Generate replacement code
  local replacement = {}
  M._boil_boilerplate(fields, replacement)

  -- Overwrite selected text with replacement
  vim.api.nvim_buf_set_lines(bufnr, vstart, vend, false, replacement)
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
