--- `npmConfig`: a project's `.npmrc` switches, handed to every npm this toolchain and
--- daukle/node run as `npm_config_*` in the environment, never as a file (D-232).
local npm_config = {}

npm_config.KEY = "npmConfig"

local KEY_SHAPE = "^[%a][%w%-]*$"

--- Keys daukle passes npm itself on the command line, which beats the environment, so a carried
--- value would be ignored without a word.
local DAUKLE_OWNED = { cache = true, offline = true, ["prefer-offline"] = true, ["prefer-online"] = true,
                       global = true, prefix = true, userconfig = true, globalconfig = true,
                       ["package-lock-only"] = true }

--- Why a key or value cannot be carried, or nil when it can.
---
--- @implNote a registry is refused, not carried, because the pins name their tarball urls: a
--- registry change is a re-resolve, and a scoped registry or a token is per host, not per project.
function npm_config.refusal(key, value)
  if type(key) ~= "string" then return "is not a config key" end
  if string.sub(key, 1, 2) == "//" or string.sub(key, 1, 1) == "_" then
    return "is a registry credential, which belongs in the user's own ~/.npmrc, never in daukle.toml"
  end
  if key == "registry" or string.match(key, "^@[^:]+:registry$") then
    return "names a registry, and the pins already name every tarball's url: resolve against it"
           .. " from the user's own ~/.npmrc instead"
  end
  if string.match(key, KEY_SHAPE) == nil then return "is not an npm config key" end
  if DAUKLE_OWNED[key] then return "is set by daukle on every npm it runs, so a value here would be ignored" end
  if type(value) ~= "string" then return "must be the value as a string, as the .npmrc line wrote it" end
  if string.find(value, "${", 1, true) then
    return "reads an environment variable, which npm expands when it reads the file and a carried"
           .. " value would freeze"
  end
  if string.find(value, "[%c]") then return "holds a control character" end
  return nil
end

--- The checked table: `{ names = sorted, values = key -> value }`. Raises on a refused key.
function npm_config.checked(config)
  local value = config[npm_config.KEY]
  local names = {}
  if value == nil then return { names = names, values = {} } end
  if type(value) ~= "table" or #value > 0 then
    error('"' .. npm_config.KEY .. '" must be a table of npm config key to its value', 0)
  end
  for key, text in pairs(value) do
    local why = npm_config.refusal(key, text)
    if why ~= nil then error(string.format('"%s.%s" %s', npm_config.KEY, tostring(key), why), 0) end
    names[#names + 1] = key
  end
  table.sort(names)
  return { names = names, values = value }
end

--- The environment npm reads the checked config from.
function npm_config.env(checked)
  local env = {}
  for _, key in ipairs(checked.names) do
    env["npm_config_" .. string.gsub(key, "%-", "_")] = checked.values[key]
  end
  return env
end

--- The keys whose values differ between two checked configs, sorted.
function npm_config.changed(checked, pinned)
  local out = {}
  for _, key in ipairs(checked.names) do
    if (pinned or {})[key] ~= checked.values[key] then out[#out + 1] = key end
  end
  for key in pairs(pinned or {}) do
    if checked.values[key] == nil then out[#out + 1] = key end
  end
  table.sort(out)
  return out
end

return npm_config
