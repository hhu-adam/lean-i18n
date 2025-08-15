import I18n

-- set_language de

def hello := t!"hello world: `a` is `b` and ```\nTest\n```\n"
def hello3 := t!"hello world"

def hello2 := t!"Test \n"

#eval hello
#eval hello2
#eval hello3

#export_i18n
