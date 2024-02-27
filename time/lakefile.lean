import Lake
open Lake DSL

-- Using this assumes that each dependency has a tag of the form `v4.X.0`.
def leanVersion : String := s!"v{Lean.versionString}"

package time where
  -- add package configuration options here
  precompileModules := true

require importGraph from git "https://github.com/leanprover-community/import-graph" @ leanVersion

@[default_target]
lean_lib Time where
  -- add library configuration options here

target time.o pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "time.o"
  let srcJob ← inputFile <| pkg.dir / "c" / "time.cpp"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  buildO "time.cpp" oFile srcJob weakArgs #["-fPIC"] "c++" getLeanTrace

extern_lib libLeanTime pkg := do
  let name := nameToStaticLib "leanTime"
  let timeO ← fetch <| pkg.target ``time.o
  buildStaticLib (pkg.nativeLibDir / name) #[timeO]
