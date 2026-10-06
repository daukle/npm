# npm-dependency-ledger

**This example is the other kind of plugin, and the difference is the point.** The examples in
`daukle/java`, `daukle/cmake`, `daukle/c`, `daukle/node` and `daukle/gradle` are managed toolchains:
daukle provisions the tool and owns the generated build file. `daukle/npm` is a dependency writer:
it edits a `package.json` that **you** own and maintain, and npm still does every piece of the
actual work.

```console
$ daukle sync
daukle: updated
```

Then `npm install` as usual: daukle wrote the dependency, npm fetches it.

Run it and `package.json` gains two things:

```json
  "dependencies": {
    "left-pad": "^1.3.0",
    "cowsay": "^1.6.0"
  },
  "daukle": {
    "managed": {
      "dependencies": ["cowsay"]
    }
  }
```

## What to look at

**`left-pad` is untouched.** The ledger under `daukle.managed` names only what daukle put there, and
that is what makes removal safe: a dependency that leaves the producer's manifest is removed on the
next sync, and a dependency daukle never added is left alone. Without the ledger, removal would
either be impossible or would delete your own entries.

**The npm package name lives in the producer, not here.** `producer/daukle.toml` says that the
module `cli` is `cowsay` at `^1.6.0`. This consumer asks for `example/greeter@^2.0.0` with module
`cli` and never names an npm package at all, which is the whole point: one producer statement, read
the same way by every consumer language.

**`kind = "path"` is a source plugin, not a toolchain.** It reads `./producer/daukle.toml` off disk.
`daukle/github` is the same role reading a manifest from a release asset, and `npm-github-source`
is that example: same producer manifest, byte for byte, fetched from a real release instead of
read off disk. Nothing here can be `[toolchains.*]`, because neither plugin declares a toolchain.

**Applying twice equals applying once.** Sync this example repeatedly and `package.json` stops
changing after the first run. That property is pinned by every success case in the plugin's own
suite, not left to inspection.

## What this example deliberately does not claim

It does not replace npm, and it does not install anything. `daukle sync` here is a file edit;
`npm install` is still yours to run, with npm still installed. If you came looking for the thing the
`java` and `cmake` examples do, this is not it, and no amount of configuration turns a
`daukle.language` plugin into a toolchain.

## How CI checks this example

The `console` block above is executed, and then the real assertion runs: the harness syncs the
example twice and compares every file in `expected/` byte for byte against what daukle wrote. The
block proves the command succeeds and says so where a reader is already looking; `expected/` proves
what it produced.

Syncing twice is the assertion, not a precaution: applying twice must equal applying once, and a
dependency writer that appended on every run would pass a single sync.
