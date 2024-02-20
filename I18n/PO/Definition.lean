import Lean
import I18n.Utils

open Lean

namespace I18n

/-!
Specification:
https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
-/

/--
A PO entry contains an untranslated string `msgid`, a translation `msgstr`
as well as optional further information.
-/
structure POEntry where
  -- TODO: The two strings, untranslated and translated, are quoted in various ways in the
  -- PO file, using " delimiters and \ escapes, but the translator does not really have to
  -- pay attention to the precise quoting format, as PO mode fully takes care of quoting for her.
  /-- untranslated String

  TODO: An empty untranslated-string is reserved to contain the header entry with the meta
  information (see Filling in the Header Entry). This header entry should be the first entry
  of the file. The empty untranslated-string is reserved for this purpose and must not
  be used anywhere else.
  -/
  msgId : String
  msgStr : String := ""
  /-- translator comments (`#`) -/
  comment : Option String := none
  /-- extracted comments  (`#.`) -/
  extrComment : Option String := none
  /-- reference (`#:`)

  TODO: References to the program’s source code, in lines that start with #:,
  are of the form file_name:line_number or just file_name. If the file_name
  contains spaces. it is enclosed within Unicode characters U+2068 and U+2069.
  -/
  ref : Option (List (String × Option Nat)) := none
  /-- flags (`#,`)

  TODO: The comma separated list of flags is used by the msgfmt program to give the
  user some better diagnostic messages.
  -/
  flags : Option <| List String := none
  /-- previous untranslated string (`#| msgid`) -/
  prevMsgId : Option String := none
  /-- message context

  TODO: The context serves to disambiguate messages with the same untranslated-string.
  It is possible to have several entries with the same untranslated-string in a PO file,
  provided that they each have a different context. Note that an empty context string and
  an absent msgctxt line do not mean the same thing.
  -/
  msgCtxt : Option String := none
  /-- previous message context (`#| msgctxt`) -/
  prevMsgCtxt : Option String := none
  -- -- TODO: Support Plurals, see `msgid_plural`
  -- /-- Plural of the -/
  -- msgIdPlural : Option String := none
  -- msgStrPlural : Option <| List String

structure POHeaderEntry where
  ProjectIdVersion : String
  ReportMsgidBugsTo : String
  POTCreationDate : String
  PORevisionDate : Option String := none
  LastTranslator : String
  LanguageTeam : Option String := none
  Language : String
  ContentType : String := "text/plain; charset=UTF-8"
  ContentTransferEncoding : String := "8bit"
  PluralForms : Option String := none

-- "Project-Id-Version: Lingohub 1.0.1\n"
-- "Report-Msgid-Bugs-To: support@lingohub.com \n"
-- "Last-Translator: Marko Bošković <marko@lingohub.com>\n"
-- "Language: de\n"
-- "MIME-Version: 1.0\n"
-- "Content-Type: text/plain; charset=UTF-8\n"
-- "Content-Transfer-Encoding: 8bit\n"
-- "Plural-Forms: nplurals=2; plural=(n != 1);\n"

structure POFile where
  /-- The first entry of a document is the header entry, which is marked with an empty `msgId`.

  See https://www.gnu.org/software/gettext/manual/html_node/Header-Entry.html -/
  header : POHeaderEntry
  entries : Array POEntry

def POFile.empty : POFile := {
  header := {
    ProjectIdVersion := ""
    ReportMsgidBugsTo := ""
    POTCreationDate := ""
    LastTranslator := ""
    Language := ""
  }
  entries := #[]}
