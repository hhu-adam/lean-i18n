# Updating the Project

As the project imports `batteries`, it is important that it uses a `batteries` commit compatible with
mathlib, or mathlib cache will brake.

Do not use `lake update`, it is simply full of footguns, and will likely not produce the result expected.

1. edit `lean-toolchain` to contain the newest version, e.g. `leanprover/lean4:v4.31.0`
2. edit `lake-manifest.json`
  - search the correct commit from https://github.com/leanprover-community/batteries/commits/main/
    and insert it ito the `batteries` entry. This is to commit where the project is bumped to the corresponding
    toolchain.
  - do the same for `lean4-cli`: https://github.com/leanprover/lean4-cli/commits/main/
3. `lake clean`
4. `lake build`
5. on github, create a PR and merge it
6. create a tag `v4.31.0` pointing to the bump commit
