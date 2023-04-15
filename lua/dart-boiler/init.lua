local M = {}

-- PROCESS HIGHLIGHTED LINES
M._boil_process_lines = function (buf_lines)
  local regex_class = "^%s*class%s*(%w*).*$"
  local regex_fields = "^%s*([A-Za-z<>]+)([!%?]*)%s+([a-zA-Z_%-]+)(%s*=?%s*[^,;:]*)[,;:]*%s*$"

  local fields = {class=nil, inherited={}, rinherited={}, required={}, optional={}}
  for index, value in ipairs(buf_lines) do
    if index == 1 then
      local _, _ , class = string.find(value, regex_class)
      fields.class = class
      goto continue
    end

    local _, _, type, scope, name, default = string.find(value, regex_fields)
    local field = {type = type, name = name, default = default}
    if scope == "!" then
      table.insert(fields.inherited, field)
    elseif scope == "!!"  then
      table.insert(fields.rinherited, field)
    elseif scope == "" then
      table.insert(fields.required, field)
    elseif scope == "?" then
      table.insert(fields.optional, field)
    end
      ::continue::
  end
  return fields
end

-- BOILERPLATE CONSTRUCTOR
M._boil_constructor = function (fields, replacement)
    table.insert(replacement, "const " .. fields.class .. "({")
  for _, field in ipairs(fields.inherited) do
      local comp = field.type .. "? " .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.rinherited) do
    local comp = "required " .. field.type .. " " .. field.name .. ","
    if field.default ~= ""  then
    comp = field.type .. " " .. field.name .. field.default .. ","
    end
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.required) do
    local comp = "required this." .. field.name .. ","
    if field.default ~= "" then
    comp = "this." .. field.name .. field.default .. ","
    end
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = "this." .. field.name .. ","
    table.insert(replacement, comp)
  end
  if #fields.inherited then
    table.insert(replacement, "}): super(")
    for _, field in ipairs(fields.inherited) do
      local comp = field.name .. ": " .. field.name .. ","
      table.insert(replacement, comp)
    end
    for _, field in ipairs(fields.rinherited) do
      local comp = field.name .. ": " .. field.name .. ","
      table.insert(replacement, comp)
    end
    table.insert(replacement, ");")
  else
    table.insert(replacement, "});")
  end
end

-- ALL FIELDS (AFTER CONSTRUCTOR)
M._boil_fields = function (fields, replacement)
  for _, field in ipairs(fields.required) do
    local comp = "final ".. field.type .. " " .. field.name .. ";"
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = "final ".. field.type .. "? " .. field.name .. ";"
    table.insert(replacement, comp)
  end
end

-- COPYWITH FUNCTION
M._boil_copywith = function (fields, replacement)
  table.insert(replacement, fields.class .. " copyWith({")
  for _, field in ipairs(fields.inherited) do
    local comp = field.type .. "? " .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.rinherited) do
    local comp = field.type .. "? " .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.required) do
    local comp = field.type .. "? " .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = field.type .. "? " .. field.name .. ","
    table.insert(replacement, comp)
  end
  table.insert(replacement, "}) =>")
  table.insert(replacement, fields.class .. "(")
  for _, field in ipairs(fields.inherited) do
    local comp = field.name .. ": " .. field.name .. " ?? this." .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.rinherited) do
    local comp = field.name .. ": " .. field.name .. " ?? this." .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.required) do
    local comp = field.name .. ": " .. field.name .. " ?? this." .. field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = field.name .. ": " .. field.name .. " ?? this." .. field.name .. ","
    table.insert(replacement, comp)
  end
  table.insert(replacement, ");")
end

M._boil_props = function (fields, replacement)
  table.insert(replacement, "@override")
  table.insert(replacement, "List<Object?> get props => [")
  for _, field in ipairs(fields.inherited) do
    local comp = field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.rinherited) do
    local comp = field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.required) do
    local comp = field.name .. ","
    table.insert(replacement, comp)
  end
  for _, field in ipairs(fields.optional) do
    local comp = field.name .. ","
    table.insert(replacement, comp)
  end
  table.insert(replacement, "];")
end

-- ALL BOILERPLATE CODE
M._boil_boilerplate = function(fields, replacement)
  M._boil_constructor(fields, replacement)

  table.insert(replacement, "")
  M._boil_fields(fields, replacement)


  if M._boil_setting_copywith then
    table.insert(replacement, "")
    M._boil_copywith(fields, replacement)
  end

  if M._boil_setting_props then
    table.insert(replacement, "")
    M._boil_props(fields, replacement)
  end

    table.insert(replacement, "}")
end

-- PUBLIC BOILERPLATE GENERATION COMMAND
M.boil = function (copyWith, props)
  M._boil_setting_copywith = copyWith or true
  M._boil_setting_props = props or false

  -- Check for Dart filetype
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "dart" then
    vim.notify("This action is only supported in Dart")
    return
  end

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
  vim.api.nvim_buf_set_lines(bufnr, vstart + 1, vend, false, replacement)
  vim.lsp.buf.format()
end

return M
