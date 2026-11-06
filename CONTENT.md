## What this repository is

The managed resolver for JavaScript: it is to `daukle/node` what `daukle/maven` is to
`daukle/java`. You write version ranges in `[toolchains.npm]`; `daukle npm:resolve --resolve` has
npm compute the closure, pins every package of it by sha256, and writes the pins to the committed
`daukle/npm/lock.lua`, which daukle loads by itself. An install then resolves no range.

```toml
[plugins]
npm = "daukle/npm@^2"

[toolchains.npm]
version = "22.15.0"
packages = { react-dom = "^18.3.1" }
devPackages = { typescript = "~5.6.0" }
```

`npmConfig` carries what an `.npmrc` would, as npm config keys to their values:
`npmConfig = { legacy-peer-deps = "true" }`. Every npm the resolve and `node:install` run gets
each as `npm_config_<key>` in its environment, and no `.npmrc` is written. A registry, a credential
(`//...`, `_...`), a `${VAR}` value and a key daukle sets itself (`cache`, `offline`, ...) are refused;
those belong in the user's own `~/.npmrc`. Changing a key needs a new resolve, as a range does
(`D-232`).

`overrides` is npm's own override object as JSON text, `overrides = '{"ms": "2.1.1"}'`, nested
forms and `$name` references included. The resolve writes it into the `package.json` npm computes
the closure from, and the pin file hands it to the target toolchain, because an offline `npm ci`
checks each lockfile edge against the `package.json` beside it and asks the registry about an edge
the overrides changed. Changing it needs a new resolve, as a range does (`D-246`).

The design is `superpowers/specs/2026-11-05-npm-resolver-design.md` in `daukle/docs` (`D-229`).
