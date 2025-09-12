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

#export_i18n
