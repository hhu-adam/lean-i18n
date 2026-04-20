import I18n

/-- warning: Translation file not found -/
#guard_msgs (substring := true) in
set_language en

#guard_msgs in
def hello := t!"hello world: `a` is `b` and ```\nTest\n```\n"

/-- info: "hello world: `a` is `b` and ```\nTest\n```" -/
#guard_msgs in
#eval hello

#guard_msgs in
def hello2 := t!"Test \n"

/-- info: "Test" -/
#guard_msgs in
#eval hello2

#guard_msgs in
def hello3 := t!"hello world"

/-- info: "hello world" -/
#guard_msgs in
#eval hello3

#guard_msgs in
def escapedString := t!"a \\` string \" with \\ escaped \\$ characters §, \
some latex blocks $0$ and $$0 = 0$$, \
and code blocks `a`, ``b`` and ```c with ` inside```"

/--
info: "a ` string \" with \\ escaped $ characters §, some latex blocks $0$ and $$0 = 0$$, and code blocks `a`, ``b`` and ```c with ` inside```"
-/
#guard_msgs in
#eval escapedString


/-- info: i18n: file created at -/
#guard_msgs (substring := true) in
#export_i18n
