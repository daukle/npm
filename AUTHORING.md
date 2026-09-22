# Authoring notes

`plugin.lua` is the whole plugin. It is published as a release asset and acquired by a
`[plugins]` table entry naming `daukle/npm@<range>`.

## What this plugin owns

A `package.json` dependency map, and a ledger at `daukle.managed.<configuration>` naming the
entries it put there. The ledger is what makes removal possible: a dependency that leaves the
producer manifest is removed on the next sync, and a dependency daukle never added is left alone.

## Conventions this repository is held to

These three are set here because they are cheap to set at publication and expensive to change
afterwards. They apply to all five of the extracted plugins, not only this one.

**An optional key with the wrong type.** This plugin raises. `modules.<m>.npm` needs `package` and
`range` as strings and says so, naming the module. `daukle/c` does not raise on its optional keys,
and both are faithful to the C they replaced, so this is a per-plugin decision rather than a rule.
State it in each repository rather than assuming the reader will infer it.

**Every error carries a `plugin.lua:<line>:` prefix.** Lua's `error()` adds it and the C this
replaced never had it. A test asserting on a message must assert on a clause, never on a token
that could also appear in the file path the message echoes: this repository's own
`reports-a-document-that-is-not-json` case sits in a directory whose name contains `json`, so
asserting on `json` alone would pass without the plugin doing anything.

**Ledger key order follows consumer order.** Two manifests declaring the same consumers in
different orders produce the same dependency entries but list `daukle.managed`'s keys in the order
the consumers ran. `test/cases/two-consumers-runtime-first` and `two-consumers-tooling-first` pin
both. The dependency maps are identical; only the ledger's key order differs. Nothing canonicalises
it, so do not assert byte equality across two manifests that order their consumers differently.

## Tests

`test/run.sh` runs every directory under `test/cases/` against a real daukle, because this
plugin's output is `daukle.json_set`'s formatting and a stub of that verb would be testing the
stub. Each case is a project: a manifest, a `package.json`, a producer, and a minimal fixture
source plugin that is deliberately not a copy of `daukle/path`.

- a case with `expected/` must sync cleanly and match every file in it, byte for byte
- a case with `expect-error.txt` must fail with a message carrying that clause
- every success case is synced **twice** and must match after both, so applying twice equals
  applying once for every case rather than only the one that remembered to say so

```sh
DAUKLE=/path/to/daukle sh test/run.sh
```

`.gitattributes` pins `* -text`, and it is load bearing rather than tidy. daukle writes LF on every
platform, so a checkout under `core.autocrlf=true` rewrites the fixtures and five of the byte-exact
cases fail on Windows for a reason that has nothing to do with the plugin. Measured, not assumed:
removing the file and re-checking out reproduces exactly those five failures.

With no `DAUKLE`, the runner looks for a build under `.daukle/`, which is where CI checks
`daukle/daukle` out.

## Provenance

The cases are the assertions of `test/test_lang_npm.c`, deleted from `daukle/daukle` when the
built-in npm language became this plugin. Recover the original with:

```sh
git -C /path/to/daukle show 8cdaa30^:test/test_lang_npm.c
```

The Lua plugin reproduces the C's output byte for byte; `updates-range-and-removes-departed` and
`writes-dev-dependencies` were compared against the C's literal expected strings directly.
