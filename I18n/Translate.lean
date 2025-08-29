import Lean
import I18n.EnvExtension
import I18n.PO.Read
import I18n.Json.Read
import I18n.InterpolatedStr
import I18n.CodeBlockExtractor

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
partial def _root_.String.extractCodeBlocks (input : String) : String × Array String := Id.run do
  let mut pos : String.Pos := 0
  let mut out : Array Char := Array.emptyWithCapacity input.utf8ByteSize
  let mut blocks : Array String := #[]
  let mut state : ExtractCodeBlocksState := .text
  while !input.atEnd pos do
    let escaped := input.get pos == '\\' && input.get (input.next pos) ∈ ['\\','`','$']
    if escaped then
      pos := input.next pos
    let c := input.get pos
    match state with
    | .text =>
      if !escaped && c == '`' then
        state := .startDelimiter c 0 #[]
      else if !escaped && c == '$' then
        state := .startDelimiter c 0 #[]
      else
        if c == '§' || c == '\\' then
          out := out.push '\\'
        out := out.push c
        pos := input.next pos
    | .startDelimiter char length blockContent =>
      let blockContent := blockContent.push c
      if !escaped && c == char && (length <= 1 || c == '`') then
        state := .startDelimiter char (length + 1) blockContent
      else
        state := .codeBlock char length blockContent
      pos := input.next pos
    | .codeBlock delimiterChar startDelimiterLength blockContent =>
      if !escaped && c == delimiterChar then
        state := .endDelimiter delimiterChar startDelimiterLength blockContent 0
      else
        state := .codeBlock delimiterChar startDelimiterLength (blockContent.push c)
        pos := input.next pos
    | .endDelimiter delimiterChar startDelimiterLength blockContent endDelimiterLength =>
      let blockContent := blockContent.push c
      if !escaped && c == delimiterChar then
        let endDelimiterLength := endDelimiterLength + 1
        if endDelimiterLength == startDelimiterLength then
          state := .text
          out := out.append s!"\{{blocks.size}}".data.toArray
          blocks := blocks.push (String.mk blockContent.toList)
        else
          state := .endDelimiter delimiterChar startDelimiterLength blockContent endDelimiterLength
      else
        state := .codeBlock delimiterChar startDelimiterLength blockContent
      pos := input.next pos
  let remainder :=
    match state with
    | .startDelimiter _ _ blockContent
    | .codeBlock _ _ blockContent
    | .endDelimiter _ _ blockContent _  => blockContent
    | .text => #[]
  return (String.mk (out ++ remainder).toList, blocks)

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
