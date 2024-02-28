import I18n.PO.ToString
import I18n.Translate
import Time
-- import DateTime

/-! # Create PO-file

To create a template PO-file, one needs to call `createPOTemplate`. This can for example
be done by adding `CreatePOT` at the very end of the main file of the package.
The template is written to a folder `.i18n/` in the package's directory as a `.pot` file.
-/

open Lean System
namespace I18n

/-- Write a PO-file to disk. -/
def POFile.save (poFile : POFile) (path : FilePath) : IO Unit :=
  -- TODO: add overwrite-check
  IO.FS.writeFile path poFile.toString

open Elab.Command in

/--
Write all collected untranslated strings into a PO file
which can be found at `.i18n/[projectName].pot`
-/
def createPOTemplate : CommandElabM Unit := do
  let projectName ← liftCoreM getProjectName
  let fileName := s!"{projectName}.pot"
  let path := (← IO.currentDir) / ".i18n"
  IO.FS.createDirAll path

  let keys := untranslatedKeysExt.getState (← getEnv)
  let langConfig ← readLanguageConfig
  let poFile : POFile := {
    header := {
      projectIdVersion := s!"{projectName} v{Lean.versionString}"
      reportMsgidBugsTo := langConfig.translationContactEmail
      potCreationDate := ← Time.getLocalTime -- (← DateTime.now).extended_format
      language := langConfig.sourceLang.toString }
    entries := keys }
  poFile.save (path / fileName)
  logInfo s!"PO-file created at {path / fileName}"

/-- Create a PO-template-file now! -/
elab "CreatePOT" : command => do
  createPOTemplate
