import Lake
open Lake DSL

package i18n where
  -- add package configuration options here

require Cli from git "https://github.com/leanprover/lean4-cli" @ "main"
require std from git "https://github.com/leanprover/std4" @ "v4.6.0"

-- require datetime from git "https://github.com/T-Brick/DateTime.git" @ "main"
-- require importGraph from git "https://github.com/leanprover-community/import-graph" @ "v4.6.1"

@[default_target]
lean_exe i18n where
  root := `Main
  -- Apparently it's needed!
  supportInterpreter := true

@[default_target]
lean_lib I18n where
  -- add library configuration options here

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
