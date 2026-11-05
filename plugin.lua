--- daukle/npm: turning npm version ranges into a closure pinned by sha256.
---
--- npm computes the closure, because a closure computed any other way would
--- differ from npm's on some project; this plugin pins it and writes the pins
--- where daukle/node installs them from. It is to daukle/node what daukle/maven
--- is to daukle/java. D-229.

daukle.plugin{
  api = 8,
  uses = { "provision", "exec", "write", "pin", "json_parse" },
  --[[ The node release table is daukle/node's and is read rather than copied,
       so both run the same npm. lib/runtimes calls no verb, so the rule that a
       required module runs under the DEPENDENT's uses has nothing to cover. ]]
  requires = {
    node = {
      url = "https://github.com/daukle/node/releases/download/3.2.0/plugin.lua",
      sha256 = "a17e72aa646864a884f47cd4c1ebcb2793dcc44630dccc280e9ae374d53e8b05",
    },
  },
}

local runtimes = daukle.require("node:lib/runtimes")
local settings = daukle.require("lib/settings")
local manifest = daukle.require("lib/manifest")
local pinning = daukle.require("lib/pinning")
local output = daukle.require("lib/output")
local translator = daukle.require("lib/translator")

--- Prints a file of the derived directory, since a task reads only project files.
local PRINT_LOCK = "process.stdout.write(require('fs').readFileSync('package-lock.json', 'utf8'))"

daukle.toolchain{
  name = "npm",
  generate = function(context)
    settings.refuse_unpinned(settings.read(context), context.resolving)
    return {}
  end,
}

local function provision_node(context, spec)
  local pick = runtimes.for_host{ os = context.host.os, arch = context.host.arch,
                                  version = spec.version }
  local root = daukle.provision{ url = pick.url, sha256 = pick.sha256, as = "node " .. pick.version }
  return root, pick
end

local function refuse_without_resolve(context)
  if not context.resolving then
    error('npm:resolve fetches every package of the closure, unpinned, to compute its sha256,'
          .. ' so it runs only as "daukle npm:resolve --resolve"', 0)
  end
end

daukle.task{
  name = "npm:resolve",
  run = function(context)
    refuse_without_resolve(context)
    local spec = settings.read(context)
    local root, pick = provision_node(context, spec)
    local node = root:tool(pick.node)
    daukle.write{ path = "package.json", text = manifest.package_json(spec) }
    -- resolving must run none of the closure's code, which a preinstall script would
    daukle.exec(node, { root:path(pick.npm), "install", "--package-lock-only", "--ignore-scripts",
                        "--no-audit", "--no-fund" })
    local lock_text = daukle.exec(node, { "-e", PRINT_LOCK }, { capture = true }).stdout
    return daukle.write{ path = output.OUTPUT,
                         text = pinning.pin_file(spec, context.toolchain.name, lock_text),
                         committed = true }
  end,
}

daukle.translator{ tool = "npm", id = "npm", translate = translator.translate }
