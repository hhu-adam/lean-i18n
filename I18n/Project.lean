module

public import Lean.Compiler.ModPkgExt
public import Lake.Load.Manifest

public section

open Lean System

namespace I18n

/-- Translations that are currently being processed. -/
structure ProjectContext where
  /-- Package identifier -/
  id : PkgId
  /-- Name used for PO and JSON filenames -/
  name : Name
  dir : FilePath
  /-- answears: is this a root package? -/
  isRoot : Bool
deriving Repr

private def packageId (name : Name) : PkgId :=
  name.toString (escape := false)

/-- Read the active workspace manifest and return its root package -/
def getRootProjectContext : IO ProjectContext := do
  let dir ← IO.currentDir
  match ← Lake.Manifest.load? (dir / "lake-manifest.json") with
  | none =>
    return { id := "project", name := `project, dir, isRoot := true }
  | some manifest =>
    return { id := packageId manifest.name, name := manifest.name, dir, isRoot := true }

/-- Resolve a Lake package identifier to its package directory in the active workspace -/
def getProjectContextForPackage (id : PkgId) : IO ProjectContext := do
  let rootDir ← IO.currentDir
  let some manifest ← Lake.Manifest.load? (rootDir / "lake-manifest.json")
    | throw <| IO.userError "i18n: lake manifest could not be read"

  if packageId manifest.name == id then
    return { id, name := manifest.name, dir := rootDir, isRoot := true }

  let some entry := manifest.packages.find? (packageId ·.name == id)
    | throw <| IO.userError s!"i18n: package '{id}' is missing from lake-manifest.json"

  let dir := match entry.src with
    | .path dir => rootDir / dir
    | .git _url _rev _inputRev? subDir? =>
      let packagesDir := manifest.packagesDir?.getD (manifest.lakeDir / "packages")
      let repositoryDir := rootDir / packagesDir / entry.name.toString (escape := false)
      match subDir? with
      | some subDir => repositoryDir / subDir
      | none => repositoryDir

  return { id, name := entry.name, dir, isRoot := false }

/-- Resolve the package of the current Lean module, falling back to the workspace root -/
def getCurrentProjectContext (env : Environment) : IO ProjectContext := do
  match env.getModulePackage? with
  | some id => getProjectContextForPackage id
  | none => getRootProjectContext
