local settings = daukle.require("lib/settings")
local pinning = daukle.require("lib/pinning")
local output = daukle.require("lib/output")

--- The instance a migrated project's npm block is written as.
local INSTANCE = "npm"

local SURFACE = "NPM-SURFACE.md: dependencies"

local function block_of(foreign)
  local config = foreign.config or {}
  local block = { version = config.version, packages = config.packages,
                  devPackages = config.devPackages }
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
local function translate(foreign)
  local block, lock_text = block_of(foreign)
  local manifest = { toolchains = { [INSTANCE] = block } }
  local spec = settings.spec_of(block, block.version)
  if not foreign.resolving then return unresolved(manifest) end
  if type(lock_text) ~= "string" then
    error("daukle/node's migrator handed over no lockfile, so there is no closure to pin", 0)
  end
  return {
    manifest = manifest,
    blockers = {},
    files = { { path = "daukle/" .. INSTANCE .. "/" .. output.OUTPUT,
                text = pinning.pin_file(spec, INSTANCE, lock_text) } },
  }
end

return { translate = translate }
