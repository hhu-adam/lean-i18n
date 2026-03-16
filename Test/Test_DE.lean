import I18n

set_language de

def hello := t!"hello world: `a` is `b` and ```\nTest\n```\n"
def hello3 := t!"hello world"
def hello2 := t!"Test \n"

/-- info: "Hallow Welt: `a` ist `b` und ```\nTest\n```" -/
#guard_msgs in
#eval hello

/-- info: "Test" -/
#guard_msgs in
#eval hello2

/-- info: "Hallo Welt" -/
#guard_msgs in
#eval hello3


def escapedString := t!"a \\` string \" with \\ escaped \\$ characters §, \
some latex blocks $0$ and $$0 = 0$$, \
and code blocks `a`, ``b`` and ```c with ` inside```"
/--
info: "ein ` String \" mit \\ escapten $ Charaktern §, Latex-Blöcken $0$ und $$0 = 0$$, und Codeblöcken `a`, ``b`` und ```c with ` inside```"
-/
#guard_msgs in
#eval escapedString


def fromSTG := t!"`¬P` means \\\"it is not the case that `P`\\\".  To enter the symbol `¬`,
type `\\not`."
/--
info: "`¬P` bedeuted \\\"es ist nicht der Fall, dass `P`\\\".  Um das Symbol `¬` einzugeben,\nschreibe `\\not`."
-/
#guard_msgs in
#eval fromSTG


#export_i18n
