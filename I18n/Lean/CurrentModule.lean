
import Lake.Load.Manifest
import Lean.Data.Name
import Lean.CoreM
import Lean.Meta.Match.MatcherInfo
import Std.Data.HashMap

open Lean Meta Elab

open Lean (Name)

namespace ImportGraph

/-- Read the name of the main module from the `lake-manifest`. -/
def getCurrentModule : IO Name := do

  match (← Lake.Manifest.load? ⟨"lake-manifest.json"⟩) with
  | none =>
    -- TODO: should this be caught?
    pure .anonymous
  | some manifest =>
    -- TODO: This assumes that the `package` and the default `lean_lib`
    -- have the same name up to capitalisation.
    -- Would be better to read the `.defaultTargets` from the
    -- `← getRootPackage` from `Lake`, but I can't make that work with the monads involved.
    return manifest.name.capitalize

/--
Helper which only returns `true` if the `module` is provided and the name `n` lies
inside it.
 -/
def isInModule (module : Option Name) (n : Name) := match module with
  | some m => m.isPrefixOf n
  | none => false

/-- Note: copied from `Mathlib.Lean.Name` -/
private def isBlackListed (declName : Name) : CoreM Bool := do
  if declName.toString.startsWith "Lean" then return true
  let env ← getEnv
  pure $ declName.isInternalDetail
   || isAuxRecursor env declName
   || isNoConfusion env declName
  <||> isRec declName <||> isMatcher declName


def allNamesByModule (p : Name → Bool) : CoreM (Std.HashMap Name (Array Name)) := do
  (← getEnv).constants.foldM (init := ∅) fun names n _ => do
    if p n && !(← isBlackListed n) then
      let some m ← findModuleOf? n | return names
      -- TODO use `modify`/`alter` when available
      match names[m]? with
      | some others => return names.insert m (others.push n)
      | none => return names.insert m #[n]
    else
      return names
