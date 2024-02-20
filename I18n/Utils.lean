import Lean

open Lean

namespace I18n
-- Copied from `import-graph`
/-- Returns the very first part of a name: for `ImportGraph.Lean.NameMap` it
returns `ImportGraph`.
-/
protected
def Name.getModule (name : Name) (s := "") : Name :=
  match name with
    | .anonymous => s
    | .num _ _ => panic s!"panic in `getModule`: did not expect numerical name: {name}."
    | .str pre s => I18n.Name.getModule pre s
