# Updating the Project

As the project imports `batteries`, it is important that it uses a `batteries` commit compatible with
mathlib, or mathlib cache will brake.

1. edit `lean-toolchain` to contain the newest version, e.g. `leanprover/lean4:v4.31.0`
2. run `lake update -R --keep-toolchain`
3. `lake build`
4. `lake test`
5. on github, create a PR and merge it
6. create a tag `v4.31.0` pointing to the bump commit
