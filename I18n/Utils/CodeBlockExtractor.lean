namespace String

/--
Utils to replace code-blocks and Latex-blocks with `§n`.
-/

def insertCodeBlocks (text : String) (blocks : Array String) : String := Id.run do
  let mut pos : String.Pos.Raw := 0
  let mut out : String := ""
  while !pos.atEnd text do
    let c := pos.get text
    let posₙ := pos.next text
    if c == '\\' then
      let cₙ := posₙ.get text
      out := out.push cₙ
      pos := posₙ.next text
    else if c == '§' then
      let (block, posAfter) := getCodeBlock text posₙ blocks
      out := out ++ block
      pos := posAfter
    else
      out := out.push c
      pos := posₙ
  return out
where
  getCodeBlock (text : String) (pos : Pos.Raw) (blocks : Array String) : String × Pos.Raw := Id.run do
    let mut pos := pos
    let mut number := ""
    while !pos.atEnd text && "0123456789".contains (pos.get text) do
      number := number.push (pos.get text)
      pos := pos.next text
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
  let mut pos : String.Pos.Raw := 0
  let mut out : Array Char := Array.emptyWithCapacity input.utf8ByteSize
  let mut blocks : Array String := #[]
  let mut state : ExtractCodeBlocksState := .text
  while !pos.atEnd input do
    let escaped := pos.get input == '\\' && (pos.next input).get input ∈ ['\\','`','$']
    if escaped then
      pos := pos.next input
    let c := pos.get input
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
        pos := pos.next input
    | .startDelimiter char length blockContent =>
      let blockContent := blockContent.push c
      if !escaped && c == char && (length <= 1 || c == '`') then
        state := .startDelimiter char (length + 1) blockContent
      else
        state := .codeBlock char length blockContent
      pos := pos.next input
    | .codeBlock delimiterChar startDelimiterLength blockContent =>
      if !escaped && c == delimiterChar then
        state := .endDelimiter delimiterChar startDelimiterLength blockContent 0
      else
        state := .codeBlock delimiterChar startDelimiterLength (blockContent.push c)
        pos := pos.next input
    | .endDelimiter delimiterChar startDelimiterLength blockContent endDelimiterLength =>
      let blockContent := blockContent.push c
      if !escaped && c == delimiterChar then
        let endDelimiterLength := endDelimiterLength + 1
        if endDelimiterLength == startDelimiterLength then
          state := .text
          out := out.append s!"§{blocks.size}".toList.toArray
          blocks := blocks.push (String.ofList blockContent.toList)
        else
          state := .endDelimiter delimiterChar startDelimiterLength blockContent endDelimiterLength
      else
        state := .codeBlock delimiterChar startDelimiterLength blockContent
      pos := pos.next input
  let remainder :=
    match state with
    | .startDelimiter _ _ blockContent
    | .codeBlock _ _ blockContent
    | .endDelimiter _ _ blockContent _  => blockContent
    | .text => #[]
  return (String.ofList (out ++ remainder).toList, blocks)
