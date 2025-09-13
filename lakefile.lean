import Lake
open Lake DSL

package i18n where

def leanVersion : String := s!"v{Lean.versionString}"

require "leanprover" / Cli @ git leanVersion
require "leanprover-community" / batteries @ git leanVersion

-- dev Dependency
-- require "leanprover-community" / importGraph @ git leanVersion

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
