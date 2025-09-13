import I18n.Translate

def input := r#"$a$ $b$ $c$ $d$ $e$ $f$ $g$ $h$ $i$ $j$ $k$"#

#guard input.extractCodeBlocks.1 == "§0 §1 §2 §3 §4 §5 §6 §7 §8 §9 §10"
#guard input.extractCodeBlocks.2 == #["$a$", "$b$", "$c$", "$d$", "$e$", "$f$", "$g$", "$h$", "$i$", "$j$", "$k$"]

/- check inserting blocks from extracted -/
#guard (
  let (key, blocks) := input.extractCodeBlocks
  key.insertCodeBlocks blocks == input )

/-- info: ("\\§0", #[]) -/
#guard_msgs in
#eval r"§0".extractCodeBlocks

/-- info: ("$a$", #[]) -/
#guard_msgs in
#eval r"\$a\$".extractCodeBlocks

/-- info: ("`a`", #[]) -/
#guard_msgs in
#eval r"\`a\`".extractCodeBlocks

/-- info: ("```a```", #[]) -/
#guard_msgs in
#eval r"\`\`\`a\`\`\`".extractCodeBlocks

/-- info: ("\\\\§0", #["$a$"]) -/
#guard_msgs in
#eval r"\\$a$".extractCodeBlocks
