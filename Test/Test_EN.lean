import I18n

/-- warning: Translation file not found: /Users/jon/Code/Lean/lean-i18n/.i18n/en/i18n.po -/
#guard_msgs in
set_language en

/-- warning: No translation (en) found for: hello world: §0 is §1 and §2 -/
#guard_msgs in
def hello := t!"hello world: `a` is `b` and ```\nTest\n```\n"

/-- warning: No translation (en) found for: hello world -/
#guard_msgs in
def hello3 := t!"hello world"

/-- warning: No translation (en) found for: Test -/
#guard_msgs in
def hello2 := t!"Test \n"

/-- info: "hello world: `a` is `b` and ```\nTest\n```" -/
#guard_msgs in
#eval hello

/-- info: "Test" -/
#guard_msgs in
#eval hello2

/-- info: "hello world" -/
#guard_msgs in
#eval hello3

/--
warning: No translation (en) found for: a ` string " with \\ escaped $ characters \§, some latex blocks §0 and §1, and code blocks §2, §3 and §4
-/
#guard_msgs in
def escapedString := t!"a \\` string \" with \\ escaped \\$ characters §, \
some latex blocks $0$ and $$0 = 0$$, \
and code blocks `a`, ``b`` and ```c with ` inside```"
/--
info: "a ` string \" with \\ escaped $ characters §, some latex blocks $0$ and $$0 = 0$$, and code blocks `a`, ``b`` and ```c with ` inside```"
-/
#guard_msgs in
#eval escapedString


#export_i18n
