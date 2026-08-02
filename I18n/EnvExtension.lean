module

public import Lean
public import I18n.PO.Definition
public import I18n.Language
public import I18n.Project

public section

/-!
We use three different env-extensions:
`untranslatedKeysExt`, `languageExt`, and `translationExt`.

The first one is used to collect the untranslated strings to write them into a `.pot` file.

The latter two contain the config (input-language, output-language, …) as well
as the existing translations between these two languages.

(Note: These latter two extenstions are separate due to issues with `Type 1` vs `Type`)
-/


open Lean

namespace I18n

register_option i18n.sortByFile : Bool := {
  defValue := false
  descr    := "sort POT entries by file order and occurrence within file, and warn about duplicate msgids"
}

/--
Contains all extraced, yet untranslated strings.
`t!"…"`, `tm!"…"`, and `String.translate` add the untranslated strings here.
-/
meta initialize untranslatedKeysExt : SimplePersistentEnvExtension POEntry (Array POEntry) ←
  registerSimplePersistentEnvExtension {
    name := `i18n_keys
    asyncMode := .sync
    addEntryFn := Array.push
    addImportedFn := Array.flatMap id }

/-- Return untranslated entries owned by one Lake package. -/
meta def getUntranslatedKeysForPackage (env : Environment) (packageId : PkgId) : Array POEntry :=
    Id.run do
  let mut keys := #[]

  for moduleName in env.header.moduleNames do
    if let some idx := env.getModuleIdx? moduleName then
      if env.getModulePackageByIdx? idx == some packageId then
        keys := keys ++ untranslatedKeysExt.getModuleEntries env idx

  let includeLocal := match env.getModulePackage? with
    | some currentPackage => currentPackage == packageId
    | none => true
  if includeLocal then
    keys := keys ++ (untranslatedKeysExt.getEntries env).toArray

  return keys

/--
Debugging only. Prints the current state of the environment extension storing all untranslated keys.
-/
meta def printTranslationKeys [Monad m] [MonadEnv m]
    [MonadLog m] [AddMessageContext m] [MonadOptions m] : m Unit := do
  let tt := untranslatedKeysExt.getState <| ← getEnv
  logInfo m!"There are {tt.size} keys marked for translation: {tt.map (·.msgId)}"

@[inherit_doc printTranslationKeys]
elab "print_translation_keys" : command => do
  printTranslationKeys

/-- The language state containing desired input- and output-language.

`translationContactEmail` is an optional email address to be written as
contact details into the generated PO-template-file.

Note that the environment extension storing this is *not* persistent across documents. -/
structure LanguageState where
  /-- The language in which the source is written. -/
  sourceLang : Language := { lang := `en }
  /-- The language that should be used for displaying translated strings. -/
  lang : Language := { lang := `en }
  /-- The contact email for problems with the generated .POT file.
  This will be written in the POT-header. -/
  translationContactEmail := ""
  /-- Use i18next-compatible json files. Not that they contain strictly less
  information than PO files. -/
  useJson := false
  /-- Sort template entries by their first occurrence in the source files.
  If this is false, template entries are sorted by `msgid`. -/
  sortByFile := false

instance : Inhabited LanguageState := ⟨{}⟩ -- all fields have default options.

/-- Register a (non-persistent) environment extension to hold the language settings. -/
initialize languageExt : EnvExtension (LanguageState) ← registerEnvExtension (pure default) (asyncMode := .sync)

/-- Set the language state. Note that this is *not* persistent across documents. -/
def setLanguageState [Monad m] [MonadEnv m] (s : LanguageState) : m Unit := do
  modifyEnv (languageExt.setState · s)

/-- Get the language state. Note that the language state is *not* persistent across documents. -/
def getLanguageState [Monad m] [MonadEnv m] : m LanguageState := do
  let env ← getEnv
  return languageExt.getState env

/--
Read the I18n config file or create it if non-existent.

This config file is a workaround to set a `LanguageState` defacto globally for the entire
package. Might be replaced if setting custom options in the lakefile ever gets implemented.

Note: The target language is not in the config file as in the current setup this is
provided through the `Language` command.
-/
def readLanguageConfigAt (projectDir : System.FilePath) (lang? : Option Language := none)
    (createIfMissing := true) : IO LanguageState := do
  let path := projectDir / ".i18n"
  let file := path / "config.json"
  if ¬ (← System.FilePath.pathExists file) then
    if createIfMissing then
      IO.FS.createDirAll path
      IO.FS.writeFile file <| "{\n" ++
        "  \"sourceLang\": \"en\",\n" ++
        -- s!"  \"lang\": \"{lang}\",\n" ++
        "  \"translationContactEmail\": \"\",\n" ++
        "  \"useJson\": false,\n" ++
        "  \"sortByFile\": false\n" ++
        "}\n"
    let state : LanguageState := {}
    return match lang? with
      | some lang => {state with lang}
      | none => state
  else
    let content ← IO.FS.readFile file
    match Json.parse content with
    | .ok res =>
      -- let lang := match res.getObjVal? "lang" with
      --   | .ok l => match l.getStr? with
      --     | .ok ll => Language.ofString ll
      --     | .error _ => panic! s!"in {file}, key `lang`: not a string!"
      --   | .error _ => panic! s!"{file} does not contain key `lang`!"
      let sourceLang := match res.getObjVal? "sourceLang" with
        | .ok l => match l.getStr? with
          | .ok ll => Language.ofString ll
          | .error _ => panic! s!"in {file}, key `sourceLang`: not a string!"
        | .error _ => {lang := `en} -- panic! s!"{file} does not contain key `sourceLang`!"
      let email := match res.getObjVal? "translationContactEmail" with
        | .ok m => match m.getStr? with
          | .ok mm => mm
          | .error _ => panic! s!"in {file}, key `translationContactEmail`: not a string!"
        | .error _ => "" -- panic! s!"{file} does not contain key `translationContactEmail`!"
      let useJson := match res.getObjVal? "useJson" with
        | .ok m => match m.getBool? with
          | .ok mm => mm
          | .error _ => panic! s!"in {file}, key `useJson`: not a boolean"
        | .error _ => false -- panic! s!"{file} does not contain key `useJson`!"
      let sortByFile := match res.getObjVal? "sortByFile" with
        | .ok m => match m.getBool? with
          | .ok mm => mm
          | .error _ => panic! s!"in {file}, key `sortByFile`: not a boolean"
        | .error _ => false

      let lang := match lang? with
      | some l => l
      | none => sourceLang

      return {
        lang := lang
        sourceLang := sourceLang
        translationContactEmail := email
        useJson := useJson
        sortByFile := sortByFile }
    | .error err =>
      panic! s!"Failed to read {file}! ({err})"

def readLanguageConfig (lang? : Option Language := none) : IO LanguageState := do
  readLanguageConfigAt (← IO.currentDir) lang?

/--
This extension holds the loaded translations `sourceLang` to `lang`.
It is up to the developer to keep it in sync with the `languageExt`.
 -/
initialize translationExt : SimplePersistentEnvExtension (String × String) (Std.HashMap String String)
  ← registerSimplePersistentEnvExtension {
      name := `i18n_translations
      asyncMode := .sync
      addEntryFn := fun hm (x : String × String) => hm.insert x.1 x.2
      /-
      Translation maps are compile-time inputs for the current module. Importing them allows an unrelated
      dependency translation with the same msgid to leak into this package.
      -/
      addImportedFn := fun _ => {} }

/--
Get the translations from the environment. It is a `HashMap String String`
mapping from the untranslated string to the translation.
-/
def getTranslations [Monad m] [MonadEnv m] : m (Std.HashMap String String) := do
  return translationExt.getState (← getEnv)
