import Lake
open Lake DSL

package i18n where

require "leanprover" / Cli @ git "v4.33.0"
require "leanprover-community" / batteries @ git "v4.33.0"

-- dev Dependency
-- require "leanprover-community" / importGraph @ git "main"

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
