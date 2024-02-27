import I18n.PO.Definition
import I18n.PO.Read
import I18n.PO.Write

namespace I18n

-- def test (s : String) := match POFile.parse s with
-- | .ok file => file.toString
-- | .error err => s!"ERROR: {err}"

-- #eval test "#  test\n"

-- #eval test "#  hallooo\n#. test\n#. more test\n#| msgid \"old msgid is nothing\"\n msgid \"text zum übersetzen\"\nmsgstr \"translated text\"\n\n#  hallooo\n#. test\n#. more test\n#| msgid \"oold msgid is nothing\"\n msgid \"text zum üübersetzen\"\nmsgstr \"translated text\"\n"


def test2 : IO Unit := do
  match ← POFile.load "test/example.po" with
  | .error err =>
    dbg_trace s!"ERROR: {err}"
  | .ok file =>
    file.save "test/example-out.po"
    dbg_trace s!"🎉: {file}"


#eval test2

-- def POEntry.ofString (s : String) : POEntry := Id.run do
--   return {
--     msgId := ""
--     msgStr := ""
--   }


-- def POFile.empty : POFile := ⟨Array.empty⟩


-- open System
-- open IO.FS

-- def POFile.load (path : FilePath) : IO POFile := do
--   if ¬ (← FilePath.pathExists path) then
--     panic "File does not exist!"


--   let content ← readFile path


--   return POFile.empty

-- #check String.append

-- def test : POEntry where
--   comment := "Hallo\nThis is a test"
--   extrComment := "bla\nblah\n"
--   msgId := "\nthis is a\nsample sentence."
--   msgStr := "das ist ein Beispielsatz."

-- def testFile : POFile where
--   entries := #[test, test]

-- #eval test.toString

-- #eval s!"{testFile}"
