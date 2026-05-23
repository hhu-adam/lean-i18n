import I18n.PO.Read
import I18n.Json.Read

open I18n

--POFile.parse on invalid escape sequence in comment should not crash
def testPoStr := "
#. §0: $$ #. \\\\begin{aligned}
#. \\\\tfrac{35}{11}\\\\cdot y &\\\\le -\\\\tfrac{22}{21}\\\\cdot x + \\\\tfrac{35}{2}  \\\\
#. \\\\tfrac{8}{9} \\\\cdot y &\\\\le x + \\\\tfrac{17}{8} #. \\\\end{aligned}
#. \\\\tfrac{8}{9} \\\\cdot y &\\\\le x + \\\\tfrac{17}{8} \\#. \\\\end{aligned}
#. \\\\end{aligned}
#. $$
#. §1: $$
#. y ≤ \\\\tfrac{34}{7}
#. $$
#: Game.Levels.Luna.L07_Linarith2
msgid \"untranslated string\"
msgstr \"übersetzter String\"
"

--Checks that the parser successfully read the file from start to finish without crashing
#guard (match POFile.parse testPoStr with | .ok _ => true | .error _ => false) == true

/--
info: some "§0: $$ #. \\begin{aligned}\n\\tfrac{35}{11}\\cdot y &\\le -\\tfrac{22}{21}\\cdot x + \\tfrac{35}{2}  \\\n\\tfrac{8}{9} \\cdot y &\\le x + \\tfrac{17}{8} #. \\end{aligned}\n\\tfrac{8}{9} \\cdot y &\\le x + \\tfrac{17}{8} \\#. \\end{aligned}\n\\end{aligned}\n$$\n§1: $$\ny ≤ \\tfrac{34}{7}\n$$"
-/
#guard_msgs in
#eval (do
  match POFile.parse testPoStr with
  | .ok f => IO.println (repr (f.entries[0]!.extrComment))
  | .error err => IO.println s!"Failed to parse: {err}"
  : IO Unit)

/--
info: Caught expected read error: File file.po does not exist!
-/
#guard_msgs in
#eval (do
  try
    let _ ← POFile.read "file.po"
    IO.println "Success"
  catch err =>
    IO.println s!"Caught expected read error: {err}"
  : IO Unit)

/--
info: Caught expected json error: File file.json does not exist!
-/
#guard_msgs in
#eval (do
  try
    let _ ← POFile.readFromJson "file.json"
    IO.println "Success"
  catch err =>
    IO.println s!"Caught expected json error: {err}"
  : IO Unit)
