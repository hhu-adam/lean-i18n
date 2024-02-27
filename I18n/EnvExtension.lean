import Lean
import I18n.PO.Definition
import I18n.Language

open Lean

namespace I18n

/-- Contains all extraced, yet untranslated strings.
TODO: instead of `String` we also want to collect metadata along the `gettext` specs. -/
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


















structure LanguageState where
  /-- The language in which the source is written. -/
  sourceLang : Language := { lang := `en }
  /-- The language that should be used for displaying translated strings. -/
  lang : Language := { lang := `en }
  -- /-- An already loaded set of translations from `sourceLang` to `Lang`. -/
  -- translations := Option <| HashMap String String
  /-- The contact email for problems with the generated .POT file.
  This will be written in the POT-header. -/
  translationContactEmail := ""

instance : Inhabited LanguageState := ⟨{}⟩ -- all fields have default options.

/-- Register a (non-persistent) environment extension to hold the language settings. -/
initialize languageExt : EnvExtension (LanguageState) ← registerEnvExtension (pure default)

/-- Set the current source language. -/
def setLanguageState [Monad m] [MonadEnv m] (s : LanguageState) : m Unit := do
  modifyEnv (languageExt.setState · s)

/-- Set the current source language. -/
def setSourceLanguage [Monad m] [MonadEnv m] (lang : Language) : m Unit := do
  modifyEnv (fun env =>
    languageExt.setState env { languageExt.getState env with sourceLang := lang })

/-- Set the current source language. -/
def setLanguage [Monad m] [MonadEnv m] (lang : Language) : m Unit := do
  modifyEnv (fun env =>
    languageExt.setState env { languageExt.getState env with lang := lang })

def getLanguageState [Monad m] [MonadEnv m] : m LanguageState := do
  let env ← getEnv
  return languageExt.getState env




/-- dubugging only -/
elab "PrintLanguage" : command => do
  let env ← getEnv
  let lang := languageExt.getState env
  logInfo s!"Language is set to {lang.lang}"


/-- Set the source language of this file.

TODO: not quite correct yet. -/
elab "SourceLanguage" lang:ident : command => do
  setSourceLanguage {lang := lang.getId}


/-- This extension holds the loaded translations `sourceLang` to `lang`.
It is up to the developer to keep it in sync with the `languageExt`.

The two are separate do to issues with `Type 1` vs `Type`.
 -/
initialize translationExt : EnvExtension (HashMap String String) ← registerEnvExtension (pure default)

def getTranslations [Monad m] [MonadEnv m] : m (HashMap String String) := do
  return translationExt.getState (← getEnv)

/-- Set the current source language. -/
def setTranslations [Monad m] [MonadEnv m] (tr : HashMap String String) : m Unit := do
  modifyEnv (fun env =>
    translationExt.setState env tr)

/-- TODO: not quite correct yet. -/
elab "Language" lang:ident : command => do
  let sample : HashMap String String :=
    HashMap.ofList [("Hello World Game", "Hello-World-Spiel")]

  setLanguage {lang := lang.getId}
  setTranslations sample
