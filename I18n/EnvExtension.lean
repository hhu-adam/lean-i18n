import Lean
import I18n.PO.Definition
import I18n.Language

/-!
We use three different env-extensions:
`untranslatedKeysExt`, `languageExt`, and `translationExt`.

The first one is used to collect the untranslated strings to write them into a `.pot` file.

The latter two contain the config (input-language, output-language, …) as well
as the existing translations between these two languages.

(Note: These latter two extenstions are separate do to issues with `Type 1` vs `Type`)
-/


open Lean

namespace I18n

/--
Contains all extraced, yet untranslated strings.
`t!"…"`, `tm!"…"`, and `String.translate` add the untranslated strings here.
-/
initialize untranslatedKeysExt : SimplePersistentEnvExtension POEntry (Array POEntry) ←
  registerSimplePersistentEnvExtension {
    name := `i18n_keys
    addEntryFn := Array.push
    addImportedFn := Array.concatMap id }

-- debugging only
def listTranslations [Monad m] [MonadEnv m]
    [MonadLog m] [AddMessageContext m] [MonadOptions m] : m Unit := do
  let env ← getEnv

  let tt := (untranslatedKeysExt.getState env)
  logInfo m!"There are {tt.size} keys for tranlation: {tt.map (·.msgId)}"

-- debugging only
elab "ListTranslations" : command => do
  listTranslations

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

instance : Inhabited LanguageState := ⟨{}⟩ -- all fields have default options.

/-- Register a (non-persistent) environment extension to hold the language settings. -/
initialize languageExt : EnvExtension (LanguageState) ← registerEnvExtension (pure default)

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
def readLanguageConfig (lang? : Option Language := none) : IO LanguageState := do
  let projectDir ← IO.currentDir
  let path := projectDir / ".i18n"
  IO.FS.createDirAll path
  let file := path / "config.json"
  if ¬ (← System.FilePath.pathExists file) then
    IO.FS.writeFile file <| "{\n" ++
      "  \"sourceLang\": \"en\",\n" ++
      -- s!"  \"lang\": \"{lang}\",\n" ++
      "  \"translationContactEmail\": \"\"\n" ++
      "}\n"
    return {}
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
        | .error _ => panic! s!"{file} does not contain key `sourceLang`!"
      let email := match res.getObjVal? "translationContactEmail" with
        | .ok m => match m.getStr? with
          | .ok mm => mm
          | .error _ => panic! s!"in {file}, key `translationContactEmail`: not a string!"
        | .error _ => panic! s!"{file} does not contain key `translationContactEmail`!"

      let lang := match lang? with
      | some l => l
      | none => sourceLang

      return {
        lang := lang
        sourceLang := sourceLang
        translationContactEmail := email }
    | .error err =>
      panic! s!"Failed to read {file}! ({err})"

/--
This extension holds the loaded translations `sourceLang` to `lang`.
It is up to the developer to keep it in sync with the `languageExt`.
 -/
initialize translationExt : SimplePersistentEnvExtension (String × String) (HashMap String String)
  ← registerSimplePersistentEnvExtension {
      name := `i18n_translations
      addEntryFn := fun hm (x : String × String) => hm.insert x.1 x.2
      addImportedFn := fun arr => HashMap.ofList (arr.concatMap id).toList }

/--
Get the translations from the environment. It is a `HashMap String String`
mapping from the untranslated string to the translation.
-/
def getTranslations [Monad m] [MonadEnv m] : m (HashMap String String) := do
  return translationExt.getState (← getEnv)
