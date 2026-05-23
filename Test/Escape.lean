import I18n
open String

#guard ("a\\b".extractCodeBlocks) == ("a\\\\b", #[])
#guard ("a\\\\b".extractCodeBlocks) == ("a\\\\\\\\b", #[])
#guard ("a\\`b".extractCodeBlocks) == ("a`b", #[])
#guard ("a\\$b".extractCodeBlocks) == ("a$b", #[])
#guard ("a§b".extractCodeBlocks) == ("a\\§b", #[])

def check (s : String) : String :=
  let (key, blocks) := s.extractCodeBlocks
  key.insertCodeBlocks blocks

#guard check "\\" == "\\"
#guard check "\\\\" == "\\\\"
#guard check "\\\\\\\\" == "\\\\\\\\"
#guard check "\\\\\\\\\\\\\\\\" == "\\\\\\\\\\\\\\\\"

#guard ("\\").insertCodeBlocks #[] == "\\"
#guard ("\\\\").insertCodeBlocks #[] == "\\"
#guard ("\\\\§0").insertCodeBlocks #["X"] == "\\X"
#guard ("\\\\\\\\§0").insertCodeBlocks #["X"] == "\\\\X"
#guard ("\\§0").insertCodeBlocks #["X"] == "§0"
