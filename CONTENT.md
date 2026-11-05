## What this repository is

The future managed resolver for JavaScript. It is being redesigned to be to `daukle/node` what
`daukle/maven` is to `daukle/java`: it resolves the declared ranges against the registry and pins
every package of the closure in `daukle.toml` by the registry's published integrity digest, so
`node:install` resolves no range and no lockfile exists.

Its earlier releases were a dependency writer that edited a `package.json` you maintained. That
mode was removed from daukle in `0.19.0`, and nothing on this branch is released yet.
