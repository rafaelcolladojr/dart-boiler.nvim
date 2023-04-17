local M = {}

-- PROCESS HIGHLIGHTED LINES
M._boil_process_lines = function (buf_lines)
  local regex_class = "^%s*class%s*(%w*).*$"
  local regex_fields = "^%s*([A-Za-z0-9<,> ]+)([!%?]*)%s+([a-zA-Z0-9_%-]+)(%s*=?%s*[^,;:]*)[,;:]*%s*$"

  local constructor_a = ""
  local constructor_b = ""
  local fields = ""
  local copyWith_a = ""
  local copyWith_b = ""
  local props = "@override\nList<Object?> get props => [\n"
  local toString = ""

  for index, value in ipairs(buf_lines) do
    if index == 1 then
      local _, _ , class = string.find(value, regex_class)
      if class == nil then
        return
      end

      -- Begining. Dealing with class name

      constructor_a = "const " .. class .. "({\n"
      copyWith_a = class .. " copyWith({\n"
      copyWith_b = "}) => " .. class .. "(\n"
      toString = "String toString() => \"" .. class .. "("
      goto continue
    end

    local _, _, type, scope, name, default = string.find(value, regex_fields)

    local field = {type = type, scope = scope, name = name, default = default}

    -- Middle. Field inserting

    constructor_a = constructor_a .. M._boil_constructor_a(field)
    constructor_b = constructor_b .. M._boil_constructor_b(field)
    fields = fields .. M._boil_fields(field)
    copyWith_a = copyWith_a .. M._boil_copywith_a(field)
    copyWith_b = copyWith_b .. M._boil_copyWith_b(field)
    props = props .. M._boil_props(field)
    toString = toString .. M._boil_toString(field)


    ::continue::
  end

  -- End. Closing functions and bodies

  if constructor_b ~= "" then
    constructor_b = "}): super(\n" ..  constructor_b
  else
    constructor_b = constructor_b .. "}"
  end
   constructor_b = constructor_b .. ");\n"

  copyWith_b = copyWith_b .. ");\n"
  props = props .. "\n];\n"
  toString = toString .. ")\";\n";

  if (M._boil_setting_copywith ~= true) then
    fields = ""
  elseif M._boil_setting_props ~= true then
    props = ""
  elseif M._boil_setting_tostring ~= true then
    toString = ""
  end

  local output = constructor_a .. constructor_b .. fields .. copyWith_a .. copyWith_b .. props .. toString
  return output .. "}\n"
end

-- BOILERPLATE CONSTRUCTOR
M._boil_constructor_a = function (field)
  local comp = ""
  if field.scope == "!" then
    comp = field.type .. "? " .. field.name .. ",\n"
  elseif field.scope == "!!" then
    comp = "required " .. field.type .. " " .. field.name .. ",\n"
    if field.default ~= "" then
      comp = field.type .. field.name .. field.default .. ",\n"
    end
  elseif field.scope == "" then
    comp = "required this." .. field.name .. ",\n"
    if field.default ~= "" then
      comp = "this." .. field.name .. field.default .. ",\n"
    end
  end
  if field.scope == "?" then
    comp = "this." .. field.name .. ",\n"
  end
  return comp
end

M._boil_constructor_b = function (field)
  if field.scope == "!" or field.scope == "!!" then
    local comp = field.name .. ": " .. field.name .. ",\n"
    return comp
  else
    return ""
  end
end

-- ALL FIELDS (AFTER CONSTRUCTOR)
M._boil_fields = function (field)
  local comp = ""
  if field.scope == "" then
    comp = "final ".. field.type .. " " .. field.name .. ";\n"
  end
  if field.scope == "?" then
    comp = "final ".. field.type .. "? " .. field.name .. ";\n"
  end
  return comp
end

-- COPYWITH FUNCTION
M._boil_copywith_a = function (field)
  if (field.type and field.name) then
    return field.type .. "? " .. field.name .. ",\n"
  else
    return ""
  end
end

M._boil_copyWith_b = function (field)
  if (field.name) then
    return field.name .. ": " .. field.name .. " ?? this." .. field.name .. ",\n"
  else
    return ""
  end
end

-- PROPS GETTER (Equatable)
M._boil_props = function (field)
  if (field.name) then
    return field.name .. ",\n"
  else return ""
  end
end

-- TOSTRING
M._boil_toString = function (field)
  if (field.name) then
    return field.name .. ": $" .. field.name .. ", "
  else
    return ""
  end
end

-- PUBLIC BOILERPLATE GENERATION COMMAND
M.boil = function (copyWith, props, toString)
  M._boil_setting_copywith = copyWith or true
  M._boil_setting_props = props or false
  M._boil_setting_tostring = toString or true

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

  local replacement = {}
  for line in string.gmatch(fields, "[^\n]+") do
    table.insert(replacement, line)
  end

  -- Overwrite selected text with replacement
  vim.api.nvim_buf_set_lines(bufnr, vstart + 1, vend, false, replacement)
  vim.lsp.buf.format()
end

return M
