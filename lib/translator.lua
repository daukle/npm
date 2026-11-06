local settings = daukle.require("lib/settings")
local pinning = daukle.require("lib/pinning")
local output = daukle.require("lib/output")
local npm_config = daukle.require("lib/npm_config")

--- The npm instance written for a node instance: `node` gives `npm`, `node-web` gives `npm-web`,
--- so two node instances of one project never meet in one npm block.
local function instance_for(node_instance)
  local suffix = string.match(node_instance, "^node(%-.+)$")
  if node_instance == "node" then return "npm" end
  return "npm" .. (suffix or ("-" .. node_instance))
end

local SURFACE = "NPM-SURFACE.md: dependencies"

local function block_of(foreign)
  local config = foreign.config or {}
  local block = { version = config.version, packages = config.packages,
                  devPackages = config.devPackages, npmConfig = config.npmConfig,
                  overrides = config.overrides }
  if foreign.instance ~= "node" then block["for"] = foreign.instance end
  return block, config.lock
end

local function unresolved(manifest)
  return {
    manifest = manifest,
    blockers = { {
      construct = "dependencies",
      where = "package.json",
      why = "pinning them fetches every package once to compute its sha256, which only a"
            .. ' resolve run may do: run "daukle migrate --resolve"',
      surface = SURFACE,
    } },
  }
end

--- Translates the dependencies daukle/node's migrator found into the npm block
--- and, in a --resolve run, the pin file of the lockfile it handed over, so the
--- migrated project installs exactly the closure the old one did.
local function config_blockers(config, where)
  local blockers = {}
  local keys = {}
  for key in pairs(config or {}) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local why = npm_config.refusal(key, config[key])
    if why ~= nil then
      blockers[#blockers + 1] = { construct = key, where = where, why = why,
                                  surface = "NPM-SURFACE.md: 4. Install, lockfile and registry configuration" }
    end
  end
  return blockers
end

local function translate(foreign)
  local block, lock_text = block_of(foreign)
  local refused = config_blockers(block.npmConfig, (foreign.config or {}).npmrc or ".npmrc")
  if #refused > 0 then return { manifest = {}, blockers = refused } end
  local instance = instance_for(foreign.instance)
  local spec = settings.spec_of(block, block.version)
  if instance ~= "npm" then block.toolchain = "npm" end
  local manifest = { toolchains = { [instance] = block } }
  if not foreign.resolving then return unresolved(manifest) end
  if type(lock_text) ~= "string" then
    error("daukle/node's migrator handed over no lockfile, so there is no closure to pin", 0)
  end
  return {
    manifest = manifest,
    blockers = {},
    files = { { path = "daukle/" .. instance .. "/" .. output.OUTPUT,
                text = pinning.pin_file(spec, instance, lock_text) } },
  }
end

return { translate = translate }
