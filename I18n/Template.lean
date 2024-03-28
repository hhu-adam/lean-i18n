import I18n.Json
import I18n.PO

import I18n.Translate
import Time
-- import DateTime

/-! # Create PO-file

To create a template PO-file, one needs to call `createPOTemplate`. This can for example
be done by adding `#create_pot` at the very end of the main file of the package.
The template is written to a folder `.i18n/` in the package's directory as a `.pot` file
(or optionally as `.json`).
-/

open Lean System

namespace I18n

/--
Write all collected untranslated strings into a template file.

Note: returns the `FilePath` of the created file, simply to display a `logInfo` in `CommandElabM`.
-/
def createTemplateAux (keys : Array POEntry) : IO FilePath := do
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
      potCreationDate := ← Time.getLocalTime -- (← DateTime.now).extended_format
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
def createTemplate : CommandElabM Unit := do
  let keys := untranslatedKeysExt.getState (← getEnv)
  let path ← createTemplateAux keys
  logInfo s!"i18n: file created at {path}"


/-- Create a i18n-template-file now! -/
elab "#export_i18n" : command => do
  createTemplate
