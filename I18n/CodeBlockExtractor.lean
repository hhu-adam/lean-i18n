inductive ExtractCodeBlocksState where
| text
| startDelimiter (char : Char) (length : Nat) (blockContent : Array Char)
| codeBlock (delimiterChar : Char) (delimiterLength : Nat) (blockContent : Array Char)
| endDelimiter (delimiterChar : Char) (startDelimiterLength : Nat) (blockContent : Array Char) (endDelimiterLength : Nat)

def substitutePlaceholder (text : String) (position : String.Pos) (blocks : Array String) (escaped : Bool) : Option (String × String.Pos) := Id.run do
  let mut pos : String.Pos := position
  if !escaped && text.get pos == '{' then
    pos := text.next pos
    let mut number := ""
    while !text.atEnd pos && '0' <= text.get pos && text.get pos <= '9' do
      number := number.push (text.get pos)
      pos := text.next pos
    if text.get pos == '}' then
      if let some n := number.toNat? then
        if h : n < blocks.size then
          return some (blocks[n], text.next pos)
  return none

def insertCodeBlocks (text : String) (blocks : Array String) : String := Id.run do
  let mut pos : String.Pos := 0
  let mut out : String := ""
  while !text.atEnd pos do
    let escaped := text.get pos == '\\' && text.get (text.next pos) ∈ ['\\','{','}']
    if escaped then
      pos := text.next pos
    if let some (block, posAfter) := substitutePlaceholder text pos blocks escaped then
      out := out ++ block
      pos := posAfter
    else
      out := out.push (text.get pos)
      pos := text.next pos
  return  String.mk out.toList
