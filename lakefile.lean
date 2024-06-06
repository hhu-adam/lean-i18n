import Lake
open Lake DSL

package i18n where
  -- add package configuration options here

def leanVersion : String := s!"v{Lean.versionString}"

require Cli from git "https://github.com/leanprover/lean4-cli" @ "main"
require batteries from git "https://github.com/leanprover-community/batteries" @ leanVersion

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

-- temporary replacement for `datetime` package.
lean_lib Time where
  srcDir := "." / "time"
  precompileModules := true

target time.o pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "time.o"
  let srcJob ← inputFile <| pkg.dir / "time" / "c" / "time.cpp"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  buildO oFile srcJob weakArgs #["-fPIC"] "c++" getLeanTrace

extern_lib libLeanTime pkg := do
  let name := nameToStaticLib "leanTime"
  let timeO ← fetch <| pkg.target ``time.o
  buildStaticLib (pkg.nativeLibDir / name) #[timeO]
