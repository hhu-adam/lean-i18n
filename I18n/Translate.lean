import Lean
import I18n.EnvExtension

open Lean
open Elab.Term


/-!
Defines `t!"yada yada"` which works like `s!` but tries to translate the provided
string frist.
-/


namespace I18n

/-- Turn an interpolated string back into a string with containing `{}`. -/
def extractKey (interpStr : TSyntax interpolatedStrKind) :
    TermElabM String := do

  let mut key := ""
  for elem in interpStr.raw.getArgs do
    -- elem is either a string literal or ...
    match elem.isInterpolatedStrLit? with
    | none => match elem with
      | .ident _ rawVal val _ =>
        -- If it is an `ident`, we want it's name
        key := key ++ "{" ++ val.toString ++ "}"
      | _ =>
        -- TODO: we don't support anything but `ident`s currently
        key := key ++ "{!TODO!}"
    | some str =>
      key := key ++ str.replace "{" "\\{"
  return key

/-- A translated string. -/
syntax:max "t!" interpolatedStr(term) : term
syntax:max "mt!" interpolatedStr(term) : term

open Elab in
elab_rules : term
  | `(t! $interpStr) => do
    let key : String ← extractKey interpStr
    modifyEnv (untranslatedKeysExt.addEntry · key)
    -- TODO: replace the string with its translation
    Term.elabTerm (← `(s! $interpStr)) none

open Elab in
elab_rules : term
  | `(mt! $interpStr) => do
    let key : String ← extractKey interpStr
    modifyEnv (untranslatedKeysExt.addEntry · key)
    -- TODO: replace the string with its translation
    Term.elabTerm (← `(m! $interpStr)) none


def _root_.String.translate [Monad m] [MonadEnv m] (s : String) : m String := do
  modifyEnv (untranslatedKeysExt.addEntry · s)
  return s



-- def parseKey (key : String)
--     (result : Array Substring := #[]) (pos₁ pos₂ : String.Pos)
--     (isEscaped inside := false) : MacroM <| Array Substring := do
--   let c := key.get! pos₂

--   if pos₂.byteIdx >= key.length then
--     let str : Substring := ⟨key, pos₁, ⟨pos₂.byteIdx - 1⟩⟩
--     return result.push str

--   if c == '\\' then
--     parseKey key result pos₁ ⟨pos₂.byteIdx + 1⟩ true inside
--   else if c == '{' then
--     if isEscaped then
--       parseKey key result pos₁ ⟨pos₂.byteIdx + 1⟩ false inside
--     else
--       -- end a string and start a term
--       let str : Substring := ⟨key, pos₁, ⟨pos₂.byteIdx - 1⟩⟩
--       -- TODO
--       parseKey key (result.push str) ⟨pos₂.byteIdx + 1⟩ ⟨pos₂.byteIdx + 1⟩ false true
--   else if c == '}' then
--     if inside then
--       -- end a term and start a string
--       let elem : Substring := ⟨key, pos₁, ⟨pos₂.byteIdx - 1⟩⟩
--       -- TODO
--       parseKey key (result.push elem) ⟨pos₂.byteIdx + 1⟩ ⟨pos₂.byteIdx + 1⟩ false false
--     else
--       parseKey key result pos₁ ⟨pos₂.byteIdx + 1⟩ false false
--   else
--     parseKey key result pos₁ ⟨pos₂.byteIdx + 1⟩ isEscaped inside


  --let y : Substring := ⟨key, i, j⟩



  --pure ()




-- def withTranslatedKey (interpStr : TSyntax interpolatedStrKind) (key : String) : MacroM Syntax := do
--   let newArgs := #[]
--   for elem in interpStr.raw.getArgs do
--     -- elem is either a string literal or ...
--     let elem ← match elem.isInterpolatedStrLit? with
--     | none =>
--       newArgs := key ++ "{" ++ "}" -- TODO: get the syntaxes raw source
--     | some str =>
--       key := key ++ str
-- return interpStr










-- variable (x : Nat)

-- #eval t!"The second \{ number: {x}. Isn't that fascinating"

-- -- Lean
-- def expandInterpolatedStrChunks
--     (chunks : Array Syntax) (mkAppend : Syntax → Syntax → MacroM Syntax)
--     (mkElem : Syntax → MacroM Syntax) : MacroM Syntax := do
--   let mut i := 0
--   let mut result := Syntax.missing
--   for elem in chunks do
--     let elem ← match elem.isInterpolatedStrLit? with
--       | none     => mkElem elem
--       | some str => mkElem (Syntax.mkStrLit str)
--     if i == 0 then
--       result := elem
--     else
--       result ← mkAppend result elem
--     i := i+1
--   return result

-- -- Kyle
-- def expandInterpolatedStrChunks'
--     (chunks : Array Syntax) (mkAppend : Term → Term → MacroM Term)
--     (mkElem : Term → MacroM Term) :
--     MacroM (String × Array (Ident × Term) × Term) := withFreshMacroScope do
--   let mut i := 0
--   let mut result : Term := ⟨Syntax.missing⟩
--   let mut elems : Array (Ident × Term) := #[]
--   let mut key := ""
--   for elem in chunks do
--     let elem ← match elem.isInterpolatedStrLit? with
--       | none     =>
--         let j := elems.size + 1
--         let n := mkIdentFrom elem (← MonadQuotation.addMacroScope (Name.appendIndexAfter `n j))
--         key := key ++ "{" ++ toString j ++ "}"
--         elems := elems.push (n, ← mkElem ⟨elem⟩)
--         pure n.raw
--       | some str =>
--         key := key ++ str
--         mkElem (Syntax.mkStrLit str)
--     if i == 0 then
--       result := ⟨elem⟩
--     else
--       result ← mkAppend result ⟨elem⟩
--     i := i+1
--   return (key, elems, result)


-- open TSyntax.Compat

-- -- Lean
-- def expandInterpolatedStr
--     (interpStr : TSyntax interpolatedStrKind) (type : Term) (toTypeFn : Term) :
--     MacroM Term := do
--   let r ← expandInterpolatedStrChunks interpStr.raw.getArgs (fun a b => `($a ++ $b)) (fun a => `($toTypeFn $a))
--   `(($r : $type))

-- -- Kyle
-- def expandInterpolatedStr'
--     (interpStr : TSyntax interpolatedStrKind) (type : Term) (toTypeFn : Term) :
--     MacroM (String × Array (Ident × Term) × Term) := do
--   let (key, elems, result) ← expandInterpolatedStrChunks' interpStr.raw.getArgs (fu(fun a => `($toTypeFn $a))n a b => `($a ++ $b)) (fun a => `($toTypeFn $a))
--   return (key, elems, ← `(($result : $type)))
