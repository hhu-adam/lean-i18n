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
    out := out.append <| "".intercalate <| comment.trim.split (· == '\n') |>.map (s!"\n#  {·}")

  if let some extrComment := e.extrComment then
    out := out.append <| "".intercalate <| extrComment.trim.split (· == '\n') |>.map (s!"\n#. {·}")

  if let some ref := e.ref then
    -- TODO: One example shows `#: src/msgcmp.c:338 src/po-lex.c:699` which is
    -- different to what's implemented here.
    let formattedRefs := ref.map (fun (file, line?) => match line? with
      | none => s!"\n#: {escapeRef file}"
      | some line => s!"\n#: {escapeRef file}:{line}" )
    out := out.append <| "".intercalate formattedRefs

  if let some flags := e.flags then
    out := out.append <| "\n#, " ++ ", ".intercalate flags

  if let some prevMsgCtxt := e.prevMsgCtxt then
    out := out.append <| s!"\n#| msgctxt \"{prevMsgCtxt}\""

  if let some prevMsgId := e.prevMsgId then
      out := out.append <|
        "\n#| msgid \"" ++
        ("\"\n#| \"".intercalate <| prevMsgId.split (· == '\n')) ++ "\""

  if let some msgCtx := e.msgCtxt then
    out := out.append <| s!"\nmsgctxt \"{msgCtx}\""

  let msgId := "\"" ++ ("\"\n\"".intercalate <| e.msgId.split (· == '\n')) ++ "\""
  out := out.append <| "\nmsgid " ++ msgId

  out := out.append <| "\nmsgstr \"" ++ ("\"\n\"".intercalate <| e.msgStr.split (· == '\n')) ++ "\""


  return out.trim

instance : ToString POEntry := ⟨POEntry.toString⟩

def POHeaderEntry.toPOEntry (header : POHeaderEntry): POEntry := Id.run do
  let mut msgStr := ""
  msgStr := msgStr.append s!"\nProject-Id-Version: {header.ProjectIdVersion}"
  msgStr := msgStr.append s!"\nReport-Msgid-Bugs-To: {header.ReportMsgidBugsTo}"
  msgStr := msgStr.append s!"\nPOT-Creation-Date: {header.POTCreationDate}"
  if let some revisionDate := header.PORevisionDate then
    msgStr := msgStr.append s!"\nPO-Revision-Date: {revisionDate}"
  msgStr := msgStr.append s!"\nLast-Translator: {header.LastTranslator}"
  msgStr := msgStr.append s!"\nLanguage-Team: {header.LanguageTeam}"
  msgStr := msgStr.append s!"\nLanguage: {header.Language}"
  msgStr := msgStr.append s!"\nContent-Type: {header.ContentType}"
  msgStr := msgStr.append s!"\nContent-Transfer-Encoding: {header.ContentTransferEncoding}"
  if let some pluralForms := header.PluralForms then
    msgStr := msgStr.append s!"\nPlural-Forms: {pluralForms}"

  return {msgId := "", msgStr := msgStr}

def POFile.toString (f : POFile) : String :=
  ("\n\n".intercalate (([f.header.toPOEntry] ++ f.entries.toList).map (fun e => s!"{e}"))) ++ "\n"

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
  let projectDir ← IO.currentDir
  let path := projectDir / ".i18n"
  IO.FS.createDirAll path

  let keys := (untranslatedKeysExt.getState (← getEnv))

  -- only for the PO header.
  let projectName := match projectDir.fileName with
  | none => "[PROJECT]"
  | some s => s

  let poFile : POFile := {
    header := {
      ProjectIdVersion := s!"{projectName} v{Lean.versionString}"
      ReportMsgidBugsTo := ""
      POTCreationDate := ""
      LastTranslator := ""
      Language := ""
    }
    entries := keys
  }

  poFile.save (path / fileName)

  logInfo s!"PO-file created at {path / fileName}"

#check System.SearchPath
