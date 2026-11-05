local function json_object(list)
  if #list.names == 0 then return "{}" end
  local lines = {}
  for index = 1, #list.names do
    local name = list.names[index]
    lines[index] = '    "' .. name .. '": "' .. list.ranges[name] .. '"'
  end
  return "{\n" .. table.concat(lines, ",\n") .. "\n  }"
end

--- The package.json npm resolves the closure from: the block's ranges and
--- nothing else, private so npm asks for no name, as daukle/node's is.
local function package_json(spec)
  return '{\n'
    .. '  "private": true,\n'
    .. '  "dependencies": ' .. json_object(spec.packages) .. ',\n'
    .. '  "devDependencies": ' .. json_object(spec.devPackages) .. '\n'
    .. '}\n'
end

return { package_json = package_json }
