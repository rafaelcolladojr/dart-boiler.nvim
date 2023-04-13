_boil_deepcompare = function(t1,t2,ignore_mt)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  if not ignore_mt and mt and mt.__eq then return t1 == t2 end
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not _boil_deepcompare(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not _boil_deepcompare(v1,v2) then return false end
  end
  return true
end

_boil_sample_input = {
  "String? name,",
  "  String? yes,",
  "String no",
  "\tDateTime! wild;",
  "bool try_this;",
}

_boil_sample_processed = {
  inherited = {
    {type = "DateTime", name = "wild"},
  },
  required = {
    {type = "String", name = "no"},
    {type = "bool", name = "try_this"},
  },
  optional = {
    {type = "String", name = "name"},
    {type = "String", name = "yes"},
  },
}

_boil_sample_constructor = {
  "const __CLASS__({",
  "\tDateTime? wild,",
  "\trequired this.no,",
  "\trequired this.try_this,",
  "\tthis.name,",
  "\tthis.yes,",
  "}): super(",
  "\twild: wild,",
  ");",
}

describe("dart-boiler", function ()
  it("Can be required", function ()
    require("dart-boiler")
  end)

  it("_boil_process_lines Returns properly formatted maps", function ()
    local lines = require("dart-boiler")._boil_process_lines(_boil_sample_input)
    local result = _boil_deepcompare(lines, _boil_sample_processed, true)
    assert.is.True(result)
  end)

  it("_boil_constructor Returns properly formatted constructor using parsed fields", function ()
    local constructor = {} 
    require("dart-boiler")._boil_constructor(_boil_sample_processed, constructor)
    local result = _boil_deepcompare(constructor, _boil_sample_constructor, true)
    assert.is.True(result)
  end)
end)
