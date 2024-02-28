import Lake
open Lake DSL

package time where
  -- add package configuration options here
  precompileModules := true

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
