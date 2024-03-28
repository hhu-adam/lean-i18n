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

def POFile.saveAsJson (poFile : POFile) (path : FilePath) : IO Unit := do
  -- TODO: add overwrite-check
  IO.FS.writeFile path poFile.toJson.pretty
