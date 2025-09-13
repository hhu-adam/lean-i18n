namespace String

/--
Utils to replace code-blocks and Latex-blocks with `§n`.
-/

def insertCodeBlocks (text : String) (blocks : Array String) : String := Id.run do
  let mut pos : String.Pos := 0
  let mut out : String := ""
  while !text.atEnd pos do
    let c := text.get pos
    let posₙ := text.next pos
    if c == '\\' then
      let cₙ := text.get posₙ
      out := out.push cₙ
      pos := text.next posₙ
    else if c == '§' then
      let (block, posAfter) := getCodeBlock text posₙ blocks
      out := out ++ block
      pos := posAfter
    else
      out := out.push c
      pos := posₙ
  return  String.mk out.toList
where
  getCodeBlock (text : String) (pos : Pos) (blocks : Array String) : String × Pos := Id.run do
    let mut pos := pos
    let mut number := ""
    while !text.atEnd pos && "0123456789".contains (text.get pos) do
      number := number.push (text.get pos)
      pos := text.next pos
    match number.toNat? with
    | some n =>
      match blocks[n]? with
      | some block =>
        return (block, pos)
      | none =>
        return ("(NOT FOUND)", pos)
    | none =>
      return ("(NOT FOUND)", pos)

private inductive ExtractCodeBlocksState where
| text
| startDelimiter (char : Char) (length : Nat) (blockContent : Array Char)
| codeBlock (delimiterChar : Char) (delimiterLength : Nat) (blockContent : Array Char)
| endDelimiter (delimiterChar : Char) (startDelimiterLength : Nat) (blockContent : Array Char) (endDelimiterLength : Nat)

/--
Replace code blocks in the string `s` with palceholders `§n`.

- A code block starts with one or many backticks (\`) and ends with the
  same amount of backticks.
- A code block might contain futher backticks, as long as the contained
  sequence is shorter than the wrapping sequence.
- `§n` corresponds to the nᵗʰ element of the returned `List`,
  i.e. the first placeholder is `§0`.
-/
def extractCodeBlocks (input : String) : String × Array String := Id.run do
  let mut pos : String.Pos := 0
  let mut out : Array Char := Array.emptyWithCapacity input.utf8ByteSize
  let mut blocks : Array String := #[]
  let mut state : ExtractCodeBlocksState := .text
  while !input.atEnd pos do
    let escaped := input.get pos == '\\' && input.get (input.next pos) ∈ ['\\','`','$']
    if escaped then
      pos := input.next pos
    let c := input.get pos
    match state with
    | .text =>
      if !escaped && c == '`' then
        state := .startDelimiter c 0 #[]
      else if !escaped && c == '$' then
        state := .startDelimiter c 0 #[]
      else
        if c == '§' || c == '\\' then
          out := out.push '\\'
        out := out.push c
        pos := input.next pos
    | .startDelimiter char length blockContent =>
      let blockContent := blockContent.push c
      if !escaped && c == char && (length <= 1 || c == '`') then
        state := .startDelimiter char (length + 1) blockContent
      else
        state := .codeBlock char length blockContent
      pos := input.next pos
    | .codeBlock delimiterChar startDelimiterLength blockContent =>
      if !escaped && c == delimiterChar then
        state := .endDelimiter delimiterChar startDelimiterLength blockContent 0
      else
        state := .codeBlock delimiterChar startDelimiterLength (blockContent.push c)
        pos := input.next pos
    | .endDelimiter delimiterChar startDelimiterLength blockContent endDelimiterLength =>
      let blockContent := blockContent.push c
      if !escaped && c == delimiterChar then
        let endDelimiterLength := endDelimiterLength + 1
        if endDelimiterLength == startDelimiterLength then
          state := .text
          out := out.append s!"§{blocks.size}".data.toArray
          blocks := blocks.push (String.mk blockContent.toList)
        else
          state := .endDelimiter delimiterChar startDelimiterLength blockContent endDelimiterLength
      else
        state := .codeBlock delimiterChar startDelimiterLength blockContent
      pos := input.next pos
  let remainder :=
    match state with
    | .startDelimiter _ _ blockContent
    | .codeBlock _ _ blockContent
    | .endDelimiter _ _ blockContent _  => blockContent
    | .text => #[]
  return (String.mk (out ++ remainder).toList, blocks)
