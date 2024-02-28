import Lake
open Lake DSL

package i18n where
  -- add package configuration options here

-- require datetime from git "https://github.com/T-Brick/DateTime.git" @ "main"
require time from "time"

@[default_target]
lean_lib I18n where
  -- add library configuration options here

-- @[default_target]
-- lean_exe gettext where
--   root := `Main
--   -- Enables the use of the Lean interpreter by the executable (e.g.,
--   -- `runFrontend`) at the expense of increased binary size on Linux.
--   -- Remove this line if you do not need such functionality.
--   supportInterpreter := true

-- @[default_target]
-- lean_exe createPOT where
--   root := `Main
--   -- Enables the use of the Lean interpreter by the executable (e.g.,
--   -- `runFrontend`) at the expense of increased binary size on Linux.
--   -- Remove this line if you do not need such functionality.
--   supportInterpreter := false
