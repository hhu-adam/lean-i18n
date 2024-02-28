import Lean

/-!
Functions to convert an interpolated string into a string and back.
-/

namespace I18n

open Lean Elab

/-- Turn an interpolated string back into a string with containing `{}`. -/
def interpolatedStrKind.toString (interpStr : TSyntax interpolatedStrKind) :
    TermElabM String := do

  let mut key := ""
  for elem in interpStr.raw.getArgs do
    -- elem is either a string literal or ...
    match elem.isInterpolatedStrLit? with
    | none => match elem with
      | .ident _ rawVal _ _ =>
        -- If it is an `ident`, we want it's name
        key := key ++ "{" ++ rawVal.toString ++ "}"
      | _ =>
        -- TODO: we don't support anything but `ident`s currently
        key := key ++ "{!TODO!}"
    | some str =>
      key := key ++ str.replace "{" "\\{"
  return key

namespace Parser

open Parser

/-- Parse a string as an interpolated string. (Modified from `Lean.Parser.runParserCategory`) -/
def String.parseAsInterpolatedStr (env : Environment) (input : String) (fileName := "<input>") :
    Except String <| TSyntax `interpolatedStrKind :=
  let input := s!"\"{input}\""
  let p := interpolatedStrFn <| andthenFn whitespace (categoryParserFnImpl `term)
  let ictx := mkInputContext input fileName
  let s := p.run ictx { env, options := {} } (getTokenTable env) (mkParserState input)
  if s.hasError then
    Except.error (s.toErrorMsg ictx)
  else if input.atEnd s.pos then
    Except.ok ⟨s.stxStack.back⟩
  else
    Except.error ((s.mkError "end of input").toErrorMsg ictx)

end Parser
