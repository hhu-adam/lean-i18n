import I18n.PO.Definition
import I18n.Translate

namespace I18n

/-- A file name containing spaces is wrapped in U+2068 and U+2069. -/
def escapeRef (s : String) : String := if
  s.contains ' ' then s!"⁨{s}⁩" else s

-- TODO: escape '"' everywhere
def POEntry.toString (e : POEntry) : String := Id.run do
  -- TODO: Header entry

  let mut out := ""

  if let some comment := e.comment then
    out := out.append <| "".intercalate <| comment.trim.split (· == '\n') |>.map (s!"#  {·}\n")

  if let some extrComment := e.extrComment then
    out := out.append <| "".intercalate <| extrComment.trim.split (· == '\n') |>.map (s!"#. {·}\n")

  if let some ref := e.ref then
    -- TODO: One example shows `#: src/msgcmp.c:338 src/po-lex.c:699` which is
    -- different to what's implemented here.
    let formattedRefs := ref.map (fun (file, line?) => match line? with
      | none => s!"#: {escapeRef file}\n"
      | some line => s!"#: {escapeRef file}:{line}\n" )
    out := out.append <| "".intercalate formattedRefs

  if let some flags := e.flags then
    out := out.append <| "#, " ++ ", ".intercalate flags ++ "\n"

  if let some prevMsgCtxt := e.prevMsgCtxt then
    out := out.append <| s!"#| msgctxt \"{prevMsgCtxt}\"\n"

  if let some prevMsgId := e.prevMsgId then
      out := out.append <|
        "#| msgid \"" ++
        ("\"\n#| \"".intercalate <| prevMsgId.split (· == '\n')) ++
        "\"\n"

  if let some msgCtx := e.msgCtxt then
    out := out.append <| s!"msgctxt \"{msgCtx}\"\n"

  let msgId := "\"" ++ ("\"\n\"".intercalate <| e.msgId.split (· == '\n')) ++ "\""
  out := out.append <| "msgid " ++ msgId ++ "\n"

  if let some msgStr := e.msgStr then
    out := out.append <| "msgstr \"" ++ ("\"\n\"".intercalate <| msgStr.split (· == '\n')) ++ "\"\n"
  else
    -- if `msgStr` is not provided, it should be identical to `msgId`
    out := out.append <| "msgstr " ++ msgId  ++ "\n"


  return out

instance : ToString POEntry := ⟨POEntry.toString⟩

def POFile.toString (f : POFile) : String :=
  "\n".intercalate <| (#[f.header] ++ f.entries).map (fun e => s!"{e}") |>.toList

instance : ToString POFile := ⟨POFile.toString⟩

open System in

def POFile.save (poFile : POFile) (path : FilePath) : IO Unit :=
  -- TODO: add overwrite-check
  IO.FS.writeFile path poFile.toString

open Lean

open Lean Meta Elab Command System

/-- Write all collected untranslated strings into a PO file which can be found
at `.i18n/` -/
def createPOTemplate (fileName : String) : CommandElabM Unit := do
  let path := (← IO.currentDir) / ".i18n"

  IO.FS.createDirAll path

  let keys := (untranslatedKeysExt.getState (← getEnv))

  let poFile : POFile := {
    entries := keys
  }

  poFile.save (path / fileName)

  logInfo s!"PO-file created at {path / fileName}"
