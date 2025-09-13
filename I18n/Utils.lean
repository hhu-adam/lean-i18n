import Lake.Load.Manifest

open Lean

namespace I18n

/-- Read the name of the current package from the lake-manifest. -/
def getProjectName : IO Name := do
  match (← Lake.Manifest.load? ⟨"lake-manifest.json"⟩) with
  | none =>
    -- TODO: What warnings can I print in `IO`?
    -- logWarning "I18n: Could not read lake-manifest.json!"
    return `project
  | some manifest =>
    return manifest.name

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

open System in

/-- Return a list of all `.po` files inside the specified folder and its subfolders. -/
partial def findFilesWithExtension (path : FilePath) (extension : String) :
    IO <| Array FilePath := do
  let dirContent ← path.readDir
  let mut poFiles : Array FilePath := #[]
  for entry in dirContent do
    let file := entry.root / entry.fileName
    if ← file.isDir then
      poFiles := poFiles ++ (← findFilesWithExtension file extension)
      pure ()
    else if file.extension = some extension then
      poFiles := poFiles.push file
  return poFiles

def escape (s : String) : String :=
  s.replace "\\" "\\\\"
    |>.replace "\"" "\\\""

def unescape (s : String) : String :=
  s.replace "\\\"" "\""
  |>.replace "\\\\" "\\"
