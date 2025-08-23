import Lean
import I18n.EnvExtension
import I18n.PO.Read
import I18n.Json.Read
import I18n.InterpolatedStr

open Lean Elab Term System

/-! # Translated strings

Defines `t!"…"`, `tm!"…"`, and `String.translate` which all take (interpolated) strings,
add them to the `untranslatedKeysExt` and try to fetch a translated (interp.) string
for replacement.

If the command `set_language` is used within that document,
-/

namespace I18n

/-- Load translations from PO-file. They can then be accessed with `I18n.getTranslations`. -/
def loadTranslations : CoreM Unit := do
  let langState ← getLanguageState
  let projectDir ← IO.currentDir
  let projectName ← getProjectName

  let ending := if langState.useJson then "json" else "po"
  let file := projectDir / ".i18n" / s!"{langState.lang}" / s!"{projectName.toString}.{ending}"
  if ¬ (← FilePath.pathExists file) then
    logWarning s!"Translation file not found: {file}"
    return ()

  let f ← if langState.useJson then
    POFile.readFromJson file
  else
    POFile.read file

  for e in f.entries do
    modifyEnv (translationExt.addEntry · (e.msgId, e.msgStr))

/-- Set the language this document should be translated into. -/
elab "set_language" lang:ident : command => do
  -- Load the language state
  let language : Language := Language.ofString lang.getId.toString
  let langState ← readLanguageConfig language
  setLanguageState {langState with lang := language}

  -- Load in the translation for that language
  Elab.Command.liftCoreM <| loadTranslations

/--
Replace code blocks in the string `s` with palceholders `§n`.

- A code block starts with one or many backticks (\`) and ends with the
  same amount of backticks.
- A code block might contain futher backticks, as long as the contained
  sequence is shorter than the wrapping sequence.
- `§n` corresponds to the nᵗʰ element of the returned `List`,
  i.e. the first placeholder is `§0`.
-/
def _root_.String.extractCodeBlocks (s : String) : String × List String :=
  -- TODO
  (s, [])

/--
Add a string to the set of untranslated strings
-/
def _root_.String.markForTranslation [Monad m] [MonadEnv m] [MonadLog m] [AddMessageContext m]
    [MonadOptions m] (s : String) : m Unit := do
  let env ← getEnv

  let (key, codeBlocks) := s.extractCodeBlocks

  let extractedComment := codeBlocks.zipIdx.foldl (init := "") fun acc (block, n) =>
        acc ++ s!"§{n}: {block}\n"

  let entry : POEntry := {
    msgId := key
    ref := some [(env.mainModule.toString, none)]
    extrComment := extractedComment }
  modifyEnv (untranslatedKeysExt.addEntry · entry)

/--
Add the string as untranslated, look up a translation
and return the translated string.
Returns the original string on failure.
-/
def _root_.String.translate [Monad m] [MonadEnv m] [MonadLog m] [AddMessageContext m]
    [MonadOptions m] (s : String) : m String := do
  let s := s.trim

  s.markForTranslation

  let langConfig : LanguageState ← getLanguageState
  if langConfig.lang == langConfig.sourceLang then
    return s
  else
    let (key, codeBlocks) := s.extractCodeBlocks
    match (← getTranslations)[key]? with
    | none =>
      -- Print a warning that the translation has not been found
      logWarning s!"No translation ({langConfig.lang}) found for: {key}"
      return s
    | some tr =>
      -- Insert the codeblocks from the original string into the translation.
      return codeBlocks.zipIdx.foldl (init := tr) fun acc (block, n) =>
        acc.replace s!"§{n}" block

/--
Translate an interpolated string by turning it into a normal string
and translating that one.
-/
def interpolatedStrKind.translate (interpStr : TSyntax `interpolatedStrKind)
    : TermElabM <| TSyntax `interpolatedStrKind := do
  let env ← getEnv
  let langState ← getLanguageState
  let key ← interpolatedStrKind.toString interpStr
  let key := key.trim
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
