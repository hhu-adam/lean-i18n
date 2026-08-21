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

/-- Which imported translation keys should be written to a template -/
inductive TemplateScope where
  /-- Export only entries owned by the current Lake package -/
  | packageOnly
  /-- Export all entries visible through imports -/
  | bundle
deriving Inhabited, BEq, Repr

/-- Records an explicit template scope so the CLI can reproduce embedded export behaviour -/
meta initialize templateScopeExt : SimplePersistentEnvExtension TemplateScope (Option TemplateScope) ←
  registerSimplePersistentEnvExtension {
    name := `i18n_template_scope
    asyncMode := .sync
    addEntryFn := fun _ scope => some scope
    addImportedFn := fun _ => none }

private meta def mergeTemplateScope (current : Option TemplateScope) (next : TemplateScope) :
    Option TemplateScope := match current, next with
  | some .bundle, _ | _, .bundle => some .bundle
  | _, .packageOnly => some .packageOnly

/-- Return the explicit template mode recorded by modules in one package. -/
meta def getTemplateScopeForPackage (env : Environment) (packageId : PkgId) :
    Option TemplateScope := Id.run do
  let mut scope := none

  for moduleName in env.header.moduleNames do
    if let some idx := env.getModuleIdx? moduleName then
      if env.getModulePackageByIdx? idx == some packageId then
        for entry in templateScopeExt.getModuleEntries env idx do
          scope := mergeTemplateScope scope entry

  let includeLocal := match env.getModulePackage? with
    | some currentPackage => currentPackage == packageId
    | none => true
  if includeLocal then
    for entry in templateScopeExt.getEntries env do
      scope := mergeTemplateScope scope entry

  return scope

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

/-- A duplicate `msgid` found while preserving source-file order. -/
structure DuplicateMsgIdWarning where
  msgId : String
  refs : List String
  deriving Inhabited

namespace DuplicateMsgIdWarning

meta def toString (warning : DuplicateMsgIdWarning) : String :=
  s!"i18n: duplicate msgid '{warning.msgId}' found in files: {", ".intercalate warning.refs}"

meta def toMessageData (warning : DuplicateMsgIdWarning) : MessageData :=
  m!"{warning.toString}"

end DuplicateMsgIdWarning

/--
By default, entries are sorted by `msgid` and duplicate keys are merged silently.
With `sortByFile`, entries keep their first source occurrence.
Duplicate `msgid`s warn because later uses disappear into the first merged entry.
-/
meta def prepareTemplateEntries (keys : Array POEntry) (sortByFile : Bool) :
    Array POEntry × Array DuplicateMsgIdWarning := Id.run do
  let groupedEntries : Std.HashMap String (Array POEntry) := keys.groupByKey (·.msgId)

  if sortByFile then
    let mut result := #[]
    let mut warnings := #[]
    let mut seen : Std.HashMap String Unit := {}

    for entry in keys do
      let id := entry.msgId
      unless seen.contains id do
        seen := seen.insert id ()
        let entries := (groupedEntries[id]?).getD #[]

        if entries.size > 1 then
          let refs := entries.flatMap (fun e => ((e.ref.getD []).map (·.1)).toArray)
          let uniqueRefs := refs.toList.eraseDups
          warnings := warnings.push { msgId := id, refs := uniqueRefs }

        result := result.push (POEntry.mergeMetaDataList entries.toList)
    return (result, warnings)
  else
    let mergedKeys : Array POEntry := groupedEntries.toArray.map (fun (_msgId, entries) =>
      POEntry.mergeMetaDataList entries.toList)
    return (mergedKeys.qsort (fun e₁ e₂ => e₁.msgId < e₂.msgId), #[])

/--
Write all collected untranslated strings into a template file.

Note: returns the `FilePath` of the created file, simply to display a `logInfo` in `CommandElabM`.
-/
meta def createTemplateAuxFor (project : ProjectContext) (keys : Array POEntry) : IO FilePath := do
  -- read config instead of `languageState` because that state only
  -- gets initialised if `set_language` is used in the document.
  let langConfig ← readLanguageConfigAt project.dir (createIfMissing := project.isRoot)

  let sourceLang := langConfig.sourceLang.toString
  let ending := if langConfig.useJson then "json" else "pot"
  let fileName := s!"{project.name}.{ending}"
  let path := project.dir / ".i18n" / sourceLang
  IO.FS.createDirAll path

  let poFile : POFile := {
    header := {
      projectIdVersion := s!"{project.name} v{Lean.versionString}"
      reportMsgidBugsTo := langConfig.translationContactEmail
      potCreationDate := (← Std.Time.PlainDate.now) |>.format "uuuu-MM-dd"
      language := sourceLang }
    entries := keys }

  if langConfig.useJson then
    poFile.saveAsJson (path / fileName)
  else
    poFile.save (path / fileName)

  return (path / fileName)

/-- Write a template for the root package. -/
meta def createTemplateAux (keys : Array POEntry) : IO FilePath := do
  createTemplateAuxFor (← getRootProjectContext) keys

open Elab.Command

private meta def createTemplateWithScope (scope : TemplateScope) : CommandElabM Unit := do
  let env ← getEnv
  let project ← getCurrentProjectContext env
  modifyEnv (templateScopeExt.addEntry · scope)
  unless project.isRoot do
    return

  let keys := match scope with
    | .packageOnly => getUntranslatedKeysForPackage env project.id
    | .bundle => untranslatedKeysExt.getState env
  let langConfig ← readLanguageConfigAt project.dir
  let opts ← getOptions
  let sortByFile := langConfig.sortByFile || opts.getBool `i18n.sortByFile false
  let (sortedKeys, warnings) := prepareTemplateEntries keys sortByFile

  for warning in warnings do
    logWarning warning.toMessageData

  let path ← createTemplateAuxFor project sortedKeys
  logInfo s!"i18n: file created at {path}"

/--
Write all untranslated strings into one template file (so Lean4Game does not break).
-/
meta def createTemplate : CommandElabM Unit := do
  createTemplateWithScope .bundle

/-- For a package-owned catalog & write only the current packages untranslated strings -/
meta def createPackageTemplate : CommandElabM Unit := do
  createTemplateWithScope .packageOnly

open Elab.Command in
elab "#export_i18n" : command => do
  createPackageTemplate
