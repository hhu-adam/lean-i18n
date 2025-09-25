import Cli.Basic
import I18n.Lean.Environment
import I18n.Template

namespace I18n

open Lean

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
      -- same as `createTemplate` but we're not in `CommandElabM`, but have the `env` explicitely
      let keys := untranslatedKeysExt.getState env
      let path ← createTemplateAux keys
      IO.println s!"i18n: file created at {path}"
    catch err =>
      throw <| IO.userError <| s!"{err}\n" ++
        "i18n: You might want to `lake build` your project first!\n"
      throw err

  if args.hasFlag "export-json" then
    let files ← findFilesWithExtension ".i18n" "po"

    for file in files do
      let outFile := file.withExtension "json"
      let po ← POFile.read file
      po.saveAsJson outFile
      IO.println s!"i18n: exported {file} to {outFile}."
  return 0
