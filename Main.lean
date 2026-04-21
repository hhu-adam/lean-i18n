module

public meta import Cli.Basic
public import I18n.Cli

open Cli

/-- Setting up command line options and help text for `lake exe graph`. -/
meta unsafe def i18n : Cmd := `[Cli|
  i18n VIA I18n.i18nCLI; ["0.1.0"]
  "I18n CLI
  Tool for internationalisation of Lean projects.
  "

  FLAGS:
    t, "template";    "Create an output template `.i18n/en/Game.pot`."
    e, "export-json"; "Exports all `.po` files in `.i18n/` to i18next-compatible `.json` format."
]

/-- `lake exe i18n` -/
public meta unsafe def main (args : List String) : IO UInt32 :=
  i18n.validate args
