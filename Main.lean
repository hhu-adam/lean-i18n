import Lean.Util.Path
import Cli.Basic
import I18n.Template

open Lean Cli

namespace I18n

/-- same as `Lean.withImportModules` but with `(loadExts := true)`. -/
unsafe def withImportModules {α : Type} (imports : Array Import) (opts : Options)
    (act : Environment → IO α) (trustLevel : UInt32 := 0) : IO α := do
  let env ← importModules (loadExts := true) imports opts trustLevel
  act env

open IO.FS IO.Process Name Core in
/-- Implementation of `lake exe i18n` command. -/
unsafe def i18nCLI (args : Cli.Parsed) : IO UInt32 := do
  if args.flags.size == 0 then
    IO.println <| IO.userError <| "i18n: expected at least one flag, see `lake exe i18n --help`!"

  if  args.hasFlag "template" then
    let module : Import := {module := (← getCurrentModule)}

    initSearchPath (← findSysroot)
    unsafe Lean.enableInitializersExecution
    try I18n.withImportModules #[module] {} (trustLevel := 1024) fun env => do
      let keys := untranslatedKeysExt.getState env
      let langConfig ← readLanguageConfig
      let (sortedKeys, warnings) := prepareTemplateEntries keys langConfig.sortByFile
      for warning in warnings do
        IO.eprintln warning.toString
      let path ← createTemplateAux sortedKeys
      IO.println s!"i18n: file created at {path}"
    catch err =>
      throw <| IO.userError <| s!"{err}\n" ++
        "i18n: You might want to `lake build` your project first!\n"
      throw err

  if args.hasFlag "export-json" then
    let files ← findFilesWithExtension ".i18n" "po"
    if files.isEmpty then
      IO.println "i18n: not found any PO files."

    for file in files do
      let outFile := file.withExtension "json"
      let po ← POFile.read file
      po.saveAsJson outFile
      IO.println s!"i18n: exported {file} to {outFile}."
  return 0

/-- Setting up command line options and help text for `lake exe graph`. -/
unsafe def i18n : Cmd := `[Cli|
  i18n VIA i18nCLI; ["0.1.0"]
  "I18n CLI
  Tool for internationalisation of Lean projects.
  "

  FLAGS:
    t, "template";    "Create an output template `.i18n/en/Game.pot`."
    e, "export-json"; "Exports all `.po` files in `.i18n/` to i18next-compatible `.json` format."
]

end I18n

/-- `lake exe i18n` -/
unsafe def main (args : List String) : IO UInt32 :=
  I18n.i18n.validate args
