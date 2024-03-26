import I18n.EnvExtension
-- import DateTime


open Lean System
namespace I18n

open Elab.Command in

def POFile.ofJson (json : Json) : Except String POFile :=
  match json with
  | .obj <| x =>
    let entries : Array POEntry := x.toArray.filterMap (fun ⟨key, val⟩ =>
      match val with
      | .str val =>
        some {msgId := key, msgStr := val}
      | _ =>
        -- TODO: This silently drops anything that is not a string.
        none)
    .ok {
      header := {
        -- Todo: is the header used for anything?
        projectIdVersion := "",
        reportMsgidBugsTo := "",
        potCreationDate := "",
        language := "" },
      entries := entries }
  | _ => throw "Invalid Json!"

def POFile.readFromJson (path : FilePath) : IO POFile := do
  if ¬ (← FilePath.pathExists path) then
    panic "File does not exist!"
  let content ← IO.FS.readFile path
  match Json.parse content with
  | .ok f =>
    match POFile.ofJson f with
    | .ok f => return f
    | .error err =>
      panic! s!"Failed to turn Json into PO file: {err}"
  | .error err =>
    panic! s!"Failed to parse Json file: {err}"
