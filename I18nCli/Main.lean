import I18nCli.Cli

/-- `lake exe i18n` -/
unsafe def main (args : List String) : IO UInt32 :=
  I18n.i18n.validate args
