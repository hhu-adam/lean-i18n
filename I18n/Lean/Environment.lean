import Lean

namespace I18n

open Lean

/-- same as `Lean.withImportModules` but with `(loadExts := true)`. -/
unsafe def withImportModules {α : Type} (imports : Array Import) (opts : Options)
    (act : Environment → IO α) (trustLevel : UInt32 := 0) : IO α := do
  let env ← importModules (loadExts := true) imports opts trustLevel
  act env
