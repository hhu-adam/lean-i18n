import I18n.PO.Definition

/-!
This file contains the tools to turn `POEntry` objects into strings.

The other direction, i.e. parsing, happens in `I18n.PO.Read` using `Parsec`.
-/

namespace I18n

namespace POEntry

/-- A file name containing spaces is wrapped in U+2068 and U+2069. -/
def escapeRef (s : String) : String := if
  s.contains ' ' then s!"⁨{s}⁩" else s
-- TODO: these characters when parsing a file!

-- TODO: escape '"' everywhere
/-- Turn a PO-entry intro a string as it would appear in the PO-file. Such a string
starts with a bunch of comment lines, followed by `msgid` and `msgstr` (and other options):

```
#  some comment
#: Project.MyFile
msgid "untranslated sentence"
msgstr "übersetzter Satz"

Note that even the comments are sometimes parsed, depending on the second character after `#`.
```
 -/
def toString (e : POEntry) : String := Id.run do
  let mut out := ""
  if let some comment := e.comment then
    out := out.append <| "".intercalate <| comment.trim.split (· == '\n') |>.map (s!"\n#  {·}")
  if let some extrComment := e.extrComment then
    out := out.append <| "".intercalate <| extrComment.trim.split (· == '\n') |>.map (s!"\n#. {·}")
  -- print the refs
  if let some ref := e.ref then
    -- TODO: One example shows `#: src/msgcmp.c:338 src/po-lex.c:699` which is
    -- different to what's implemented here.
    let formattedRefs := ref.map (fun (file, line?) => match line? with
      | none => s!"\n#: {escapeRef file}"
      | some line => s!"\n#: {escapeRef file}:{line}" )
    out := out.append <| "".intercalate formattedRefs
  -- print the flags
  if let some flags := e.flags then
    out := out.append <| "\n#, " ++ ", ".intercalate flags

  if let some prevMsgCtxt := e.prevMsgCtxt then
    out := out.append <| s!"\n#| msgctxt \"{prevMsgCtxt}\""
  if let some prevMsgId := e.prevMsgId then
      out := out.append <|
        "\n#| msgid \"" ++
        ("\\n\"\n#| \"".intercalate <| prevMsgId.split (· == '\n')) ++ "\""
  if let some msgCtx := e.msgCtxt then
    out := out.append <| s!"\nmsgctxt \"{msgCtx}\""
  -- print the translation
  let msgId := "\"" ++ ("\\n\"\n\"".intercalate <| e.msgId.split (· == '\n')) ++ "\""
  let msgStr := "\"" ++ ("\\n\"\n\"".intercalate <| e.msgStr.split (· == '\n')) ++ "\""
  out := out.append <| "\nmsgid " ++ msgId
  out := out.append <| "\nmsgstr " ++ msgStr
  return out.trim

instance : ToString POEntry := ⟨POEntry.toString⟩

/-- Paring the header entry into a `POHeaderEntry`. -/
def toPOHeaderEntry (header : POEntry): POHeaderEntry := Id.run do
  return {
    -- TODO: implement!
    projectIdVersion := ""
    reportMsgidBugsTo := ""
    potCreationDate := ""
    poRevisionDate := ""
    lastTranslator := ""
    languageTeam := ""
    language := ""
    contentType := ""
    contentTransferEncoding := ""
    pluralForms := ""
  }

end POEntry

namespace POHeaderEntry

/-- The header entry is marked in the PO-file with `msgid = ""`. -/
def toPOEntry (header : POHeaderEntry): POEntry := Id.run do
  let mut msgStr := ""
  msgStr := msgStr.append s!"Project-Id-Version: {header.projectIdVersion}"
  msgStr := msgStr.append s!"\nReport-Msgid-Bugs-To: {header.reportMsgidBugsTo}"
  msgStr := msgStr.append s!"\nPOT-Creation-Date: {header.potCreationDate}"
  if let some revisionDate := header.poRevisionDate then
    msgStr := msgStr.append s!"\nPO-Revision-Date: {revisionDate}"
  msgStr := msgStr.append s!"\nLast-Translator: {header.lastTranslator}"
  msgStr := msgStr.append s!"\nLanguage-Team: {header.languageTeam}"
  msgStr := msgStr.append s!"\nLanguage: {header.language}"
  msgStr := msgStr.append s!"\nContent-Type: {header.contentType}"
  msgStr := msgStr.append s!"\nContent-Transfer-Encoding: {header.contentTransferEncoding}"
  if let some pluralForms := header.pluralForms then
    msgStr := msgStr.append s!"\nPlural-Forms: {pluralForms}"
  return {msgId := "", msgStr := msgStr}

end POHeaderEntry

namespace POFile

/-- Print a PO file as string.
A PO file is a series of po-entries, the first one should come from the header.
-/
def toString (f : POFile) : String :=
  ("\n\n".intercalate (([f.header.toPOEntry] ++ f.entries.toList).map (fun e => s!"{e}"))) ++ "\n"

instance : ToString POFile := ⟨POFile.toString⟩

end POFile
