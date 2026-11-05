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

The design is `superpowers/specs/2026-11-05-npm-resolver-design.md` in `daukle/docs` (`D-229`).
