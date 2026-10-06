# npm

The npm language plugin for daukle. It writes resolved module coordinates into a package.json dependency map and keeps a ledger of the entries it owns, so a dependency daukle added is removed again when it leaves the manifest and a dependency it never owned is left alone.

## Examples

- [`npm-dependency-ledger`](examples/npm-dependency-ledger): **This example is the other kind of plugin, and the difference is the point.**

## What this plugin is

A `daukle.language` named `npm`. It is a dependency **writer** in adopted mode: it edits a
`package.json` that **you** own and maintain, and it needs npm already installed. daukle adds and
removes entries; npm still does every piece of the actual work.

**It is one half of a pair and the names are easy to confuse.** `daukle/node` is managed mode: it
provisions the runtime, generates a `package.json` into the derived directory and drives the npm
that runtime bundles. This plugin is for a project that already has a `package.json` it intends to
keep.

They are two repositories rather than one because core refuses a single plugin chunk that declares
`exec` or `provision` to also declare a language.

## The ledger is what makes removal possible

Entries daukle added are recorded at `daukle.managed.<configuration>` inside your `package.json`.
A dependency that leaves the producer manifest is removed on the next sync, and **a dependency
daukle never added is left alone.**

Without that ledger the plugin could only ever add. Removing would mean guessing which entries were
ours, and guessing wrong in a file the user owns is the one failure a dependency writer must not
have.

## Where the rest is

The declaration, the keys and the exact sync behaviour live in this repository's `wiki/index.md`,
which is rendered at <https://daukle.github.io/guide/>. `AUTHORING.md` is the measured detail for
anyone changing the plugin, and `examples/npm-dependency-ledger` is a project that runs, with its
expected `package.json` compared byte for byte in CI.

## License

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
