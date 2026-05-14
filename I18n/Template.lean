module

public import Lean
import Std.Time
import I18n.Json
import I18n.PO
public meta import Std.Time.Zoned
public meta import I18n.EnvExtension
public meta import I18n.Json.Write
public meta import Std.Time.Format
public meta import I18n.PO.Write
public meta import I18n.Utils

import I18n.Translate
public import I18n.PO.Definition

public section

/-! # Create PO-file

To create a template PO-file, one needs to call `createPOTemplate`. This can for example
be done by adding `#create_pot` at the very end of the main file of the package.
The template is written to a folder `.i18n/` in the package's directory as a `.pot` file
(or optionally as `.json`).
-/

open Lean System

namespace I18n

namespace POEntry

/-- Merge two PO-entries. This will append refs and flags from the second entry to the first. -/
meta def mergeMetadata (entry other : POEntry) := { entry with
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
meta def mergeMetaDataList (a : List POEntry) : POEntry := match a with
  | [] => default
  | x₀ :: rest => x₀.mergeMetadata (mergeMetaDataList rest)

end POEntry

/--
Write all collected untranslated strings into a template file.

Note: returns the `FilePath` of the created file, simply to display a `logInfo` in `CommandElabM`.
-/
meta def createTemplateAux (keys : Array POEntry) : IO FilePath := do
  let projectName ← getProjectName

  -- read config instead of `languageState` because that state only
  -- gets initialised if `set_language` is used in the document.
  let langConfig ← readLanguageConfig

  let sourceLang := langConfig.sourceLang.toString
  let ending := if langConfig.useJson then "json" else "pot"
  let fileName := s!"{projectName}.{ending}"
  let path := (← IO.currentDir) / ".i18n" / sourceLang
  IO.FS.createDirAll path

  let poFile : POFile := {
    header := {
      projectIdVersion := s!"{projectName} v{Lean.versionString}"
      reportMsgidBugsTo := langConfig.translationContactEmail
      potCreationDate := (← Std.Time.PlainDate.now) |>.format "uuuu-MM-dd"
      language := sourceLang }
    entries := keys }

  if langConfig.useJson then
    poFile.saveAsJson (path / fileName)
  else
    poFile.save (path / fileName)

  return (path / fileName)

open Elab.Command in

/--
Write all collected untranslated strings into a template file.
-/
meta def createTemplate : CommandElabM Unit := do
  let keys := untranslatedKeysExt.getState (← getEnv)

  -- there might be multiple keys with identical msgId, which we need to merge
  let groupedEntries : Std.HashMap String (Array POEntry) := keys.groupByKey (·.msgId)
  let mergedKeys : Array POEntry := groupedEntries.toArray.map (fun (_msgId, entries) =>
    POEntry.mergeMetaDataList entries.toList)

  let path ← createTemplateAux mergedKeys
  logInfo s!"i18n: file created at {path}"

/-- Create a i18n-template-file now! -/
elab "#export_i18n" : command => do
  createTemplate
