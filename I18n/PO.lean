import I18n.PO.Definition
import I18n.PO.Read
import I18n.PO.Write


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
