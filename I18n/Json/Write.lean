module

public import I18n.EnvExtension

public section

/-! # Create JSON-file

Compatible with `i18next`.
-/

open Lean System
namespace I18n

/--
Convert PO-File to Json. Filters out all empty translations, unless they are
marked with the flag `lean-empty`.
-/
def POFile.toJson (poFile : POFile) : Json :=
  Json.mkObj <| Array.toList <| poFile.entries.filterMap fun entry =>
    let flags := entry.flags.getD ∅
    if flags.contains "lean-empty" || !entry.msgStr.isEmpty then
      some (entry.msgId, Json.str entry.msgStr)
    else
      none

def POFile.saveAsJson (poFile : POFile) (path : FilePath) : IO Unit := do
  -- TODO: add overwrite-check
  IO.FS.writeFile path poFile.toJson.pretty
