import Lake
open Lake DSL

package i18n where
  -- add package configuration options here

-- require datetime from git "https://github.com/T-Brick/DateTime.git" @ "main"
-- require importGraph from git "https://github.com/leanprover-community/import-graph" @ "v4.6.1"

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

-- temporary replacement for `datetime` package.
lean_lib Time where
  srcDir := "." / "time"
  precompileModules := true

target time.o pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "time.o"
  let srcJob ← inputFile <| pkg.dir / "time" / "c" / "time.cpp"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  buildO "time.cpp" oFile srcJob weakArgs #["-fPIC"] "c++" getLeanTrace

extern_lib libLeanTime pkg := do
  let name := nameToStaticLib "leanTime"
  let timeO ← fetch <| pkg.target ``time.o
  buildStaticLib (pkg.nativeLibDir / name) #[timeO]
