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
  "class ClassName {",
  "\tDateTime! wild;",
  "String!! escape;",
  "String no;",
  "bool try_this;",
  "bool maybe = true;",
  "String? name,",
  "  String? yes,",
  "}",
}

_boil_sample_processed = {
  class = "ClassName",
  inherited = {
    {type = "DateTime", name = "wild", default = ""},
  },
  rinherited = {
    {type = "String", name = "escape", default = ""},
  },
  required = {
    {type = "String", name = "no", default = ""},
    {type = "bool", name = "try_this", default = ""},
    {type = "bool", name = "maybe", default = " = true"},
  },
  optional = {
    {type = "String", name = "name", default = ""},
    {type = "String", name = "yes", default = ""},
  },
}

_boil_sample_constructor = {
  "const ClassName({",
  "DateTime? wild,",
  "required String escape,",
  "required this.no,",
  "required this.try_this,",
  "this.maybe = true,",
  "this.name,",
  "this.yes,",
  "}): super(",
  "wild: wild,",
  "escape: escape,",
  ");",
}

_boil_sample_copywith = {
  "ClassName copyWith({",
  "DateTime? wild,",
  "String? escape,",
  "String? no,",
  "bool? try_this,",
  "bool? maybe,",
  "String? name,",
  "String? yes,",
  "}) =>",
  "ClassName(",
  "wild: wild ?? this.wild,",
  "escape: escape ?? this.escape,",
  "no: no ?? this.no,",
  "try_this: try_this ?? this.try_this,",
  "maybe: maybe ?? this.maybe,",
  "name: name ?? this.name,",
  "yes: yes ?? this.yes,",
  ");",
}

_boil_sample_props = {
  "@override",
  "List<Object?> get props => [",
  "wild,",
  "escape,",
  "no,",
  "try_this,",
  "maybe,",
  "name,",
  "yes,",
  "];",
}

_boil_sample_tostring = "String toString() => \"ClassName(wild: $wild, escape: $escape, no: $no, try_this: $try_this, maybe: $maybe, name: $name, yes: $yes )\";"

describe("dart-boiler", function ()
  it("_boil_process_lines Returns properly formatted maps", function ()
    local lines = require("dart-boiler")._boil_process_lines(_boil_sample_input)
    local result = _boil_deepcompare(lines, _boil_sample_processed, true)
    assert.is.True(result)
  end)

  it("_boil_constructor Returns properly formatted constructor using parsed fields", function ()
    local constructor = {}
    require("dart-boiler")._boil_constructor(_boil_sample_processed, constructor)
    P(constructor)
    local result = _boil_deepcompare(constructor, _boil_sample_constructor, true)
    assert.is.True(result)
  end)

  it("_boil_copywith Returns properly formatted copyWith function using parsed fields", function ()
    local copywith = {}
    require("dart-boiler")._boil_copywith(_boil_sample_processed, copywith)
    local result = _boil_deepcompare(copywith, _boil_sample_copywith, true)
    assert.is.True(result)
  end)

  it("_boil_props Returns properly formatted pros getter using parsed fields", function ()
    local props = {}
    require("dart-boiler")._boil_props(_boil_sample_processed, props)
    local result = _boil_deepcompare(props, _boil_sample_props, true)
    assert.is.True(result)
  end)

  it("_boil_tostring Returns properly formatted toString function using parsed fields", function ()
    local tostring = {}
    require("dart-boiler")._boil_tostring(_boil_sample_processed, tostring)
    P(tostring)
    local result = _boil_deepcompare(tostring, _boil_sample_tostring, true)
    assert.is.True(result)
  end)
end)
