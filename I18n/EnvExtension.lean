import Lean

open Lean

namespace I18n

/-- Contains all extraced, yet untranslated strings.

TODO: instead of `String` we also want to collect metadata along the `gettext` specs. -/
initialize untranslatedKeysExt : SimplePersistentEnvExtension String (Array String) ←
  registerSimplePersistentEnvExtension {
    name := `i18n_keys
    addEntryFn := Array.push
    addImportedFn := Array.concatMap id }

def listTranslations [Monad m] [MonadEnv m]
    [MonadLog m] [AddMessageContext m] [MonadOptions m] : m Unit := do
  let env ← getEnv

  let tt := (untranslatedKeysExt.getState env)
  logInfo m!"There are {tt.size} keys for tranlation: {tt}"

    -- debug function
elab "ListTranslations" : command => do
  listTranslations
