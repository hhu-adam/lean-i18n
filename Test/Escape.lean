import I18n
open String

#eval "\\"
#eval "\\\\"
#eval "\\\\\\\\"
#eval "\\\\\\\\\\\\\\\\"

#eval ("\\").length
#eval ("\\\\").length
#eval ("\\\\\\\\").length
#eval ("\\\\\\\\\\\\\\\\").length

#eval ("a\\b".extractCodeBlocks)
#eval ("a\\\\b".extractCodeBlocks)
#eval ("a\\`b".extractCodeBlocks)
#eval ("a\\$b".extractCodeBlocks)
#eval ("a§b".extractCodeBlocks)

def check (s : String) : String :=
  let (key, blocks) := s.extractCodeBlocks
  key.insertCodeBlocks blocks

#eval check "\\"
#eval check "\\\\"
#eval check "\\\\\\\\"
#eval check "\\\\\\\\\\\\\\\\"

/-
For some reason #eval ("\\").insertCodeBlocks #[] doesn't work.
-/
#eval ("\\\\").insertCodeBlocks #[]
#eval ("\\\\§0").insertCodeBlocks #["X"]
#eval ("\\\\\\\\§0").insertCodeBlocks #["X"]
#eval ("\\§0").insertCodeBlocks #["X"]

def test (s : String) : String :=
  let (k, b) := s.extractCodeBlocks
  s!"input={repr s}\n key={repr k}\n reinsert={repr (k.insertCodeBlocks b)}"

#eval test "\\"
#eval test "\\\\"
#eval test "\\\\\\\\"
#eval test "\\\\\\\\\\\\\\\\"
