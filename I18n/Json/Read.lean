module

public import I18n.EnvExtension

public section

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
    throw <| IO.userError s!"File {path} does not exist!"
  let content ← IO.FS.readFile path
  match Json.parse content with
  | .ok f =>
    match POFile.ofJson f with
    | .ok f => return f
    | .error err =>
      throw <| IO.userError s!"Failed to turn Json file {path} into PO file: {err}"
  | .error err =>
    throw <| IO.userError s!"Failed to parse Json file {path}: {err}"
