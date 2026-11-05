local LOCK_VERSION = 3

local function package_name(path)
  local name = string.match(path, "^.*node_modules/(.+)$")
  if name == nil then
    error('the lockfile names "' .. path .. '", which is not a node_modules path', 0)
  end
  return name
end

local function is_registry_tarball(url)
  return type(url) == "string" and string.match(url, "^https://") ~= nil
         and string.match(url, "%.tgz$") ~= nil
end

local function platform_list(value)
  if value == nil then return nil end
  local out = {}
  for index = 1, #value do out[index] = value[index] end
  return out
end

local function checked_entry(path, entry)
  if entry.link then
    error('"' .. path .. '" is a link to a local package, which npm writes for a workspace or'
          .. ' a file: dependency; only registry packages can be pinned', 0)
  end
  if not is_registry_tarball(entry.resolved) then
    error(string.format('"%s" resolves to "%s", not to a registry tarball: only a registry'
                        .. ' package can be pinned by its digest', path, tostring(entry.resolved)), 0)
  end
  return {
    path = path,
    name = package_name(path),
    version = entry.version,
    url = entry.resolved,
    os = platform_list(entry.os),
    cpu = platform_list(entry.cpu),
    libc = platform_list(entry.libc),
  }
end

--- Every package of a parsed package-lock.json, sorted by its node_modules
--- path, as `{ path, name, version, url, os, cpu, libc }`.
---
--- @implNote a bundled package (`inBundle`) has no tarball of its own: it
--- arrives inside its parent's, so it is skipped rather than pinned.
local function entries(lock)
  if lock.lockfileVersion ~= LOCK_VERSION then
    error("npm wrote lockfile version " .. tostring(lock.lockfileVersion) .. ", and this plugin"
          .. " reads version " .. LOCK_VERSION .. ", which npm 7 and later write", 0)
  end
  local paths = {}
  for path in pairs(lock.packages or {}) do
    if path ~= "" and not lock.packages[path].inBundle then paths[#paths + 1] = path end
  end
  table.sort(paths)
  local out = {}
  for index = 1, #paths do out[index] = checked_entry(paths[index], lock.packages[paths[index]]) end
  return out
end

return { entries = entries }
