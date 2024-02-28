import Lake.Load.Manifest

open Lean

namespace I18n

/-- Read the name of the current package from the lake-manifest. -/
def getProjectName : CoreM Name := do
  match (← Lake.Manifest.load? ⟨"lake-manifest.json"⟩) with
  | none =>
    logWarning "I18n: Could not read lake-manifest.json!"
    return `project
  | some manifest =>
    return manifest.name
