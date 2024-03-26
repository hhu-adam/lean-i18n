import I18n.I18next.Write
import I18n.PO.ToString
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

/-- Write a PO-file to disk. -/
def POFile.save (poFile : POFile) (path : FilePath) : IO Unit :=
  -- TODO: add overwrite-check
  IO.FS.writeFile path poFile.toString

open Elab.Command in

/--
Write all collected untranslated strings into a template file.
-/
def createTemplate : CommandElabM Unit := do
  let projectName ← liftCoreM getProjectName

  -- read config instead of `languageState` because that state only
  -- gets initialised if `set_language` is used in the document.
  let langConfig ← readLanguageConfig

  let sourceLang := langConfig.sourceLang.toString
  let ending := if langConfig.useJson then "json" else "po"
  let fileName := s!"{projectName}.{ending}"
  let path := (← IO.currentDir) / ".i18n" / sourceLang
  IO.FS.createDirAll path

  let keys := untranslatedKeysExt.getState (← getEnv)

  let poFile : POFile := {
    header := {
      projectIdVersion := s!"{projectName} v{Lean.versionString}"
      reportMsgidBugsTo := langConfig.translationContactEmail
      potCreationDate := ← Time.getLocalTime -- (← DateTime.now).extended_format
      language := sourceLang }
    entries := keys }

  if langConfig.useJson then
    poFile.saveAsJson (path / fileName)
    logInfo s!"Json-file created at {path / fileName}"
  else
    poFile.save (path / fileName)
    logInfo s!"PO-file created at {path / fileName}"
  -- -- save a copy as Json file for i18next support
  -- poFile.saveAsJson

/-- Create a i18n-template-file now! -/
elab "#export_i18n" : command => do
  createTemplate
