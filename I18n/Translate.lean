import Lean
import I18n.EnvExtension
import I18n.PO.Read
import I18n.InterpolatedStr

open Lean Elab Term System

/-! # Translated strings

Defines `t!"…"`, `tm!"…"`, and `String.translate` which all take (interpolated) strings,
add them to the `untranslatedKeysExt` and try to fetch a translated (interp.) string
for replacement.

If the command `Language` is used within that document,
-/

namespace I18n

/-- Load translations from PO-file. They can then be accessed with `I18n.getTranslations`. -/
def loadTranslations : CoreM Unit := do
  let langState ← getLanguageState
  let projectDir ← IO.currentDir
  let projectName ← getProjectName
  let file := projectDir / ".i18n" / s!"{projectName.toString}-{langState.lang}.po"
  if ¬ (← FilePath.pathExists file) then
    logWarning s!"Translation file not found: {file}"
    return ()
  let f ← POFile.read file
  for e in f.entries do
    modifyEnv (translationExt.addEntry · (e.msgId, e.msgStr))

/-- Set the language this document should be translated into. -/
elab "Language" lang:ident : command => do
  -- Load the language state
  let language : Language := Language.ofString lang.getId.toString
  let langState ← readLanguageConfig language
  setLanguageState {langState with lang := language}

  -- Load in the translation for that language
  Elab.Command.liftCoreM <| loadTranslations

/--
Add a string to the set of untranslated strings
-/
def _root_.String.markForTranslation [Monad m] [MonadEnv m] [MonadLog m] [AddMessageContext m]
    [MonadOptions m] (s : String) : m Unit := do
  let env ← getEnv
  let entry : POEntry := {
    msgId := s
    ref := some [(env.mainModule.toString, none)] }
  modifyEnv (untranslatedKeysExt.addEntry · entry)


/--
Add the string as untranslated, look up a translation
and return the translated string.
Returns the original string on failure.
-/
def _root_.String.translate [Monad m] [MonadEnv m] [MonadLog m] [AddMessageContext m]
    [MonadOptions m] (s : String) : m String := do
  s.markForTranslation

  let langConfig : LanguageState ← getLanguageState
  let sTranslated ← if langConfig.lang == langConfig.sourceLang then
    pure s
  else
    match (← getTranslations).find? s with
    | none =>
      -- Print a warning that the translation has not been found
      logWarning s!"No translation ({langConfig.lang}) found for: {s}"
      pure s
    | some tr =>
      pure tr
  return sTranslated

/--
Translate an interpolated string by turning it into a normal string
and translating that one.
-/
def interpolatedStrKind.translate (interpStr : TSyntax `interpolatedStrKind)
    : TermElabM <| TSyntax `interpolatedStrKind := do
  let env ← getEnv
  let langState ← getLanguageState
  let key ← interpolatedStrKind.toString interpStr
  let newInterpStr ← if langState.lang == langState.sourceLang then
    -- We need to add the string as untranslated,
    -- but we can just return the existing string.
    key.markForTranslation
    pure interpStr
  else
    -- Search for a translation
    let tKey : String ← key.translate
    -- Parse the translation
    let newInterpStr ← match Parser.String.parseAsInterpolatedStr env tKey with
      | .ok newInterpStr => pure newInterpStr
      | .error err =>
        logError s!"Could not parse translated string: {err}\n\ninput: {key}"
        pure interpStr
  return newInterpStr

/-- A translated string. -/
syntax:max "t!" interpolatedStr(term) : term

/-- A translated string as message data. -/
syntax:max "mt!" interpolatedStr(term) : term

elab_rules : term
  | `(t! $interpStr) =>  withFreshMacroScope do
    let newInterpStr ← interpolatedStrKind.translate interpStr
    Term.elabTerm (← `(s! $newInterpStr)) none
  | `(mt! $interpStr) =>  withFreshMacroScope do
    let newInterpStr ← interpolatedStrKind.translate interpStr
    Term.elabTerm (← `(m! $newInterpStr)) none
