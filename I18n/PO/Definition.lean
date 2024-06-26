import Lean
import I18n.Utils

open Lean

namespace I18n

/-! # PO File
Specification:
https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html

Additionally, we use one new flag: `lean-format` to mark interpolated strings.
-/

/--
A PO entry contains an untranslated string `msgid`, a translation `msgstr`
as well as optional further information.
-/
structure POEntry where
  /-- untranslated string

  Note: An empty untranslated-string is reserved for the header entry, see `POHeaderEntry`.
  -/
  msgId : String
  /-- translated string -/
  msgStr : String := ""
  /-- translator comments (`# `) -/
  comment : Option String := none
  /-- extracted comments  (`#.`) -/
  extrComment : Option String := none
  /-- reference (`#:`)

  References to the program’s source code. Either `(fileName, none)` or
  `(fileName, lineNumber)`.
  If the file_name contains spaces, it should be enclosed within unicode
  characters U+2068 and U+2069, see `I18n.POEntry.escapeRef`.
  -/
  ref : Option (List (String × Option Nat)) := none
  /-- flags (`#,`) -/
  flags : Option <| List String := none
  /-- previous untranslated string (`#| msgid`) -/
  prevMsgId : Option String := none
  /-- message context

  The context serves to disambiguate messages with the same untranslated-string.

  TODO: unused.
  -/
  msgCtxt : Option String := none
  /-- previous message context (`#| msgctxt`) -/
  prevMsgCtxt : Option String := none
  -- -- TODO: add support for plurals, see `msgid_plural`
  -- /-- Plural of the -/
  -- msgIdPlural : Option String := none
  -- msgStrPlural : Option <| List String

instance : Inhabited POEntry where
  default := {msgId := "«oops»"} -- not using `""` just in case because that marks the header entry

/-- The parsed header information of a PO file. This is encoded with
`msgid = ""` (and no `msgctxt`) in the po file. -/
structure POHeaderEntry where
  projectIdVersion : String
  reportMsgidBugsTo : String
  potCreationDate : String
  poRevisionDate : Option String := none
  lastTranslator : String := ""
  languageTeam : Option String := none
  language : String
  contentType : String := "text/plain; charset=UTF-8"
  contentTransferEncoding : String := "8bit"
  pluralForms : Option String := none

/-- A PO-file is a document containing translations of strings into a different language. -/
structure POFile where
  /-- The header, see https://www.gnu.org/software/gettext/manual/html_node/Header-Entry.html -/
  header : POHeaderEntry
  /-- Each entry contains one translation into the target language. -/
  entries : Array POEntry

namespace POEntry

/-- Merge two PO-entries. This will append refs and flags from the second entry to the first. -/
def mergeMetadata (entry other : POEntry) := { entry with
  ref := match entry.ref, other.ref with
  | none, none => none
  | some ref₁, none => ref₁
  | none, some ref₂ => ref₂
  | some ref₁, some ref₂ => some (ref₁ ++ ref₂)
  flags := match entry.flags, other.flags with
  | none, none => none
  | some flags₁, none => flags₁
  | none, some flags₂ => flags₂
  | some flags₁, some flags₂ => some (flags₁ ++ flags₂)
  -- TODO: Other stuff too?
}

/-- Joins the metadata of multiple PO-entries. -/
def mergeMetaDataList (a : List POEntry) : POEntry := match a with
  | [] => default
  | x₀ :: rest => x₀.mergeMetadata (mergeMetaDataList rest)

end POEntry
