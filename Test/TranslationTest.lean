import I18n.Translate

def testCorrectNumberOfCodeBlocks : IO Unit := do
  let input := r#"$a$ $b$ $c$ $d$ $e$ $f$ $g$ $h$ $i$ $j$ $k$"#
  let (t, _) := input.extractCodeBlocks
  let exp := "{0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10}"
  if t == exp then
    IO.println "Test for correct number of code blocks passed. ✅"
  else
    IO.println "Test for correct number of code blocks did not pass. ❌"

def testCorrectInsertionOfCodeBlocks : IO Unit := do
  let input := r#"$a$ $b$ $c$ $d$ $e$ $f$ $g$ $h$ $i$ $j$ $k$"#
  let (t, b) := input.extractCodeBlocks
  let res := insertCodeBlocks t b
  if res == input then
    IO.println "Test for correct insertion of code blocks passed. ✅"
  else
    IO.println "Test for correct insertion of code blocks did not pass. ❌"

def runAllTests : IO Unit := do
  IO.println "Running tests..."
  testCorrectNumberOfCodeBlocks
  testCorrectInsertionOfCodeBlocks
  IO.println "All tests completed"

def main : IO Unit := runAllTests
