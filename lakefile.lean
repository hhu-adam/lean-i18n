import Lake
open Lake DSL

package i18n where
  -- add package configuration options here

def leanVersion : String := s!"v{Lean.versionString}"

require "leanprover" / Cli @ git "27f69ad2b2b88fb0844b1c17624576a3654a335e"
require "leanprover-community" / batteries @ git leanVersion

-- require datetime from git "https://github.com/T-Brick/DateTime.git" @ "main"
-- require importGraph from git "https://github.com/leanprover-community/import-graph" @ leanVersion

@[default_target]
lean_exe i18n where
  root := `Main
  -- Apparently it's needed!
  supportInterpreter := true

@[default_target]
lean_lib I18n where
  -- add library configuration options here
