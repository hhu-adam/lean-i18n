import I18n.EnvExtension
-- import DateTime

/-! # Create JSON-file

Compatible with `i18next`.
-/

open Lean System
namespace I18n

def POFile.toJson (poFile : POFile) : Json :=
  Json.mkObj <| poFile.entries.map (fun entry => (entry.msgId, Json.str entry.msgStr)) |>.toList

open Elab.Command in

def POFile.saveAsJson (poFile : POFile) : CommandElabM Unit := do
  let langConfig ← readLanguageConfig
  let sourceLang := langConfig.sourceLang.toString

  let projectName ← liftCoreM getProjectName
  let fileName := s!"{projectName}.json"
  let path := (← IO.currentDir) / ".i18n" / sourceLang
  IO.FS.createDirAll path
  -- TODO: add overwrite-check
  IO.FS.writeFile (path / fileName) poFile.toJson.pretty
  logInfo s!"Json-file created at {path / fileName}"
