import Lake
open Lake DSL

package i18n where

require "leanprover" / Cli @ git "main"
require "leanprover-community" / batteries @ git "main"

-- dev Dependency
-- require "leanprover-community" / importGraph @ git "main"

@[default_target]
lean_exe i18n where
  root := `Main
  -- Apparently it's needed!
  supportInterpreter := true

@[default_target]
lean_lib I18n where

@[test_driver]
lean_lib Test where
  globs := #[.submodules `Test]
