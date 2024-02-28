import Lean

open Lean

namespace I18n

/-- A language known to the translation system. -/
structure Language where
  /-- `ISO 639` language code, lower case. For example `en`, `de`, `fr` … -/
  lang : Name
  /-- `ISO 3166` country code, upper case. For example `DE`, `CH`, `AT`, … -/
  country : Option Name := none
  /-- From GNU gettext:
  > ‘variant’ is a variant designator.
  > The variant designator (lowercase) can be a script designator,
  > such as ‘latin’ or ‘cyrillic’.
  -/
  variant : Option Name := none
deriving BEq, Inhabited

namespace Language

/--The string representation of a language can be `en`,
`de_CH`, or `ar_JO@latin`. -/
def toString (l : Language) : String :=
  match l.country, l.variant with
    | none, none => s!"{l.lang}"
    | none, some v => s!"{l.lang}@{v}"
    | some c, none => s!"{l.lang}_{c}"
    | some c, some v => s!"{l.lang}_{c}@{v}"

instance : ToString Language := ⟨Language.toString⟩

@[inherit_doc Language.toString]
def ofString (s : String) : Language :=
  match s.split (· = '_') with
  | [langVariant] =>
    match langVariant.split (· = '@') with
    | [lang]          => ⟨lang, none, none⟩
    | [lang, variant] => ⟨lang, none, variant⟩
    | _               => panic! s!"Invalid language string: {s}"
  | [lang, countryVariant] =>
    match countryVariant.split (· = '@') with
    | [country]          => ⟨lang, country, none⟩
    | [country, variant] => ⟨lang, country, variant⟩
    | _                  => panic! s!"Invalid language string: {s}"
  | _ =>
    panic! s!"Invalid language string: {s}"

end Language
