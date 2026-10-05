# daukle/npm

A dependency **writer**, in adopted mode. It edits a `package.json` that **you** own and maintain,
and needs npm already installed. For managed mode, where daukle owns the generated `package.json`
and provisions the runtime, use `daukle/node` instead.

## Declaring it

```toml
[plugins]
npm = "daukle/npm@^1"

[[consumers]]
id = "node"
language = "npm"
file = "package.json"
configuration = "dependencies"

  [consumers.dependencies."example/greeter"]
  version = "^2.0.0"
  modules = ["cli"]
```

## The ledger is what makes removal possible

Entries daukle added are recorded at `daukle.managed.<configuration>` inside your `package.json`.
A dependency that leaves the producer manifest is removed on the next sync; **a dependency daukle
never added is left alone.** Without the ledger the plugin could only add, or would have to guess.

## What to know

A module block needs `package` and `range` as strings, and a wrong type **raises**, naming the
module. That is a per-plugin decision rather than an organization rule: `daukle/c` does not raise
on its optional key, and both are faithful to the C each replaced.

**Ledger key order follows consumer order.** Two manifests declaring the same consumers in
different orders produce identical dependency maps and list `daukle.managed`'s keys differently.
Nothing canonicalises it, so do not compare two such manifests byte for byte.
