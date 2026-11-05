local output = daukle.require("lib/output")

local KNOWN_KEYS = { version = true, packages = true, devPackages = true, ["for"] = true,
                     [output.PINNED_FROM] = true }

local RESOLVE = '"daukle npm:resolve --resolve"'

local SCOPED = "^@[%w][%w%.%_%-]*/[%w][%w%.%_%-]*$"
local PLAIN = "^[%w][%w%.%_%-]*$"

local function config_of(context)
  if context.toolchain ~= nil then return context.toolchain.config end
  return context.config
end

local function reject_unknown_keys(config)
  for key in pairs(config) do
    if KNOWN_KEYS[key] == nil then
      error(string.format('"%s" is not a key this toolchain knows: a misspelled key would'
                          .. ' otherwise be ignored and resolve the wrong closure silently', key), 0)
    end
  end
end

local function version_of(context)
  local version = (context.toolchain ~= nil and context.toolchain.version)
                  or config_of(context).version
  if version == nil then
    error('an npm toolchain needs a "version", the node whose npm resolves the closure:'
          .. ' write the node toolchain\'s, so both run the same npm', 0)
  end
  return version
end

local function target_of(config)
  local target = config["for"] or "node"
  if type(target) ~= "string" or string.match(target, "^[%w_]+$") == nil then
    error('"for" names the toolchain the pins land on, such as "node", not "'
          .. tostring(target) .. '"', 0)
  end
  return target
end

--- @implNote ranges are written into a package.json without a json escaper,
--- so a character that would need escaping is refused at the edge instead,
--- as daukle/node refuses it.
local function checked_range(name, range, key)
  if type(range) ~= "string" then
    error(string.format('%s."%s" must be a version range as a string, not a %s',
                        key, name, type(range)), 0)
  end
  if range == "" then
    error(string.format('%s."%s" is empty, and npm has no empty range', key, name), 0)
  end
  if string.match(range, '^[%w%s%.%-%+%*|<>=~^%(%)]+$') == nil then
    error(string.format('%s."%s" is "%s", which is not a registry version range: a git, file,'
                        .. ' url or alias specifier resolves outside the registry, and only a'
                        .. ' registry tarball can be pinned', key, name, range), 0)
  end
  return range
end

local function checked_packages(config, key)
  local packages = config[key]
  if packages == nil then return {}, {} end
  if type(packages) ~= "table" or #packages > 0 then
    error('"' .. key .. '" must be a table of package name to version range', 0)
  end
  local names = {}
  for name, range in pairs(packages) do
    if type(name) ~= "string"
       or (string.match(name, PLAIN) == nil and string.match(name, SCOPED) == nil) then
      error(string.format('"%s" is not an npm package name: a name is "lodash" or'
                          .. ' "@scope/name"', tostring(name)), 0)
    end
    checked_range(name, range, key)
    names[#names + 1] = name
  end
  table.sort(names)
  return names, packages
end

--- Reads and checks the block. Returns `{ version, target, packages, devPackages }`,
--- each package list as `{ names = sorted, ranges = name -> range }`.
local function read(context)
  local config = config_of(context)
  reject_unknown_keys(config)
  local names, ranges = checked_packages(config, "packages")
  local dev_names, dev_ranges = checked_packages(config, "devPackages")
  for index = 1, #dev_names do
    if ranges[dev_names[index]] ~= nil then
      error(string.format('"%s" is in both "packages" and "devPackages", and npm keeps one',
                          dev_names[index]), 0)
    end
  end
  return {
    version = version_of(context),
    target = target_of(config),
    packages = { names = names, ranges = ranges },
    devPackages = { names = dev_names, ranges = dev_ranges },
    pinnedFrom = config[output.PINNED_FROM],
  }
end

local function changed_names(list, pinned, out)
  for name, range in pairs(list.ranges) do
    if pinned[name] ~= range then out[#out + 1] = name end
  end
  for name in pairs(pinned) do
    if list.ranges[name] == nil then out[#out + 1] = name end
  end
end

--- Refuses a build whose ranges have no pins, or pins resolved from other ranges: an ordinary
--- build may not resolve a range, and installing the old closure would ignore the edit silently.
local function refuse_unpinned(spec, resolving)
  if resolving or (#spec.packages.names == 0 and #spec.devPackages.names == 0) then return end
  if spec.pinnedFrom == nil then
    error("these packages have no pins yet, and a build installs only pinned packages: run "
          .. RESOLVE .. ", which writes daukle/npm/" .. output.OUTPUT, 0)
  end
  local changed = {}
  changed_names(spec.packages, spec.pinnedFrom.packages or {}, changed)
  changed_names(spec.devPackages, spec.pinnedFrom.devPackages or {}, changed)
  if #changed > 0 then
    table.sort(changed)
    error("the ranges of " .. table.concat(changed, ", ") .. " changed since the pins in daukle/npm/"
          .. output.OUTPUT .. " were resolved: run " .. RESOLVE .. " again", 0)
  end
end

return { read = read, refuse_unpinned = refuse_unpinned }
