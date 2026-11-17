import Lake
open Lake DSL

package i18n where

-- Using this assumes that each dependency has a tag of the form `v4.X.0`.
def leanVersion : String := s!"v{Lean.versionString}"

require "leanprover" / Cli @ git leanVersion
require "leanprover-community" / batteries @ git leanVersion

-- dev Dependency
-- require "leanprover-community" / importGraph @ git leanVersion

@[default_target]
lean_lib I18n where

lean_lib I18nCli where
  globs := #[.submodules `I18nCli]

@[default_target]
lean_exe i18n where
  root := `I18nCli.Main
  -- Apparently it's needed!
  supportInterpreter := true

@[test_driver]
lean_lib Test where
  globs := #[.submodules `Test]
