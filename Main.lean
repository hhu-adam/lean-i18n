import Cli
import I18n.Cli

open Cli

/-- Setting up command line options and help text for `lake exe gettext`. -/
def gettext : Cmd := `[Cli|
  graph VIA getTextCLI; ["0.0.1"]
  ""

  FLAGS:
    -- reduce;               "Remove transitively redundant edges."
    -- to : ModuleName;      "Only show the upstream imports of the specified module."
    -- "from" : ModuleName;  "Only show the downstream dependencies of the specified module."
    -- "exclude-meta";       "Exclude any files starting with `Mathlib.[Tactic|Lean|Util|Mathport]`."
    -- "include-deps";       "Include used files from other projects (e.g. lake packages)"

  ARGS:
    -- ...outputs : String;  "Filename(s) for the output. \
    --   If none are specified, generates `import_graph.dot`. \
    --   Automatically chooses the format based on the file extension. \
    --   Currently `.dot` is supported, \
    --   and if you have `graphviz` installed then any supported output format is allowed."
]


/-- `lake exe gettext` -/
def main (args : List String) : IO UInt32 :=
  gettext.validate args
