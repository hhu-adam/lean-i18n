import I18n.PO.Definition

/-! # Parse PO-Files

The main function of this file is `POFile.read`, which uses `Parsec` to
parse a PO-file and returns a `POFile`.
-/

open Lean

namespace I18n

namespace POFile.Parser

/-- Parse a string of po-comment references. -/
def parseRefs (ref : String) : List (String × Option Nat) :=
  ref.split (· = ',') |>.map (·.trim) |>.map fun s =>
    match s.split (· = ':') with
    | [s']    => (s', none)
    | [s', n] => (s', n.toNat!)
    | _       => panic! s!"Failed to parse ref: \"{s}\"."

/-- Parse a comma-separated string of PO-flags. -/
def parseFlags (flags : String) : List String :=
  flags.split (· = ',') |>.map (·.trim)

open Parsec

/-- Internal function used by `ws_maxOneLF` -/
partial def skipWs_maxOneLF (it : String.Iterator) (foundLF := false) : String.Iterator :=
  if it.hasNext then
    let c := it.curr
    if c = '\u000a' then
      if foundLF then
        it
      else
        skipWs_maxOneLF it.next true
    else if c = '\u0009' ∨ c = '\u000d' ∨ c = '\u0020' then
      skipWs_maxOneLF it.next foundLF
    else
      it
  else
   it

/-- Consume zero or more whitespace characters, but maximal one newline character -/
@[inline]
def ws_maxOneLF : Parsec Unit := fun it =>
  .success (skipWs_maxOneLF it) ()

/-- Parse the next character as an escaped code. -/
def escapedChar : Parsec Char := do
  let c ← anyChar
  match c with
  | '\\' => return '\\'
  | '"'  => return '"'
  -- | '/'  => return '/'
  -- | 'b'  => return '\x08'
  -- | 'f'  => return '\x0c'
  | 'n'  => return '\n'
  | 'r'  => return '\x0d'
  | 't'  => return '\t'
  -- | 'u'  =>
  --   let u1 ← hexChar; let u2 ← hexChar; let u3 ← hexChar; let u4 ← hexChar
  --   return Char.ofNat $ 4096*u1 + 256*u2 + 16*u3 + u4
  | _ => fail s!"illegal escape sequence: \\{c}"

/--
Parses the content of a PO-file string, not including the initial `"`.
Accepts multiline strings which are closed and reopened around each line-break
 -/
partial def strCore (acc : String := "") : Parsec String := do
  let c ← peek!
  if c = '"' then
    -- end of string found. try to look for continuation on next line
    skip
    ws_maxOneLF
    let c ← peek?
    match c with
    | none =>
      -- found eof
      return acc
    | some '"' =>
      -- concatenate strings split over multiple lines
      skip
      return ← strCore acc
    | some _ =>
      -- string is completed
      return acc
  else
    -- process character inside the string
    let c ← anyChar
    if c = '\\' then
      strCore (acc.push (← escapedChar))
    else
      strCore (acc.push c)

/-- Helper function to peek at the second character coming up. -/
@[inline]
def peek2? : Parsec (Option Char) := fun it =>
  if it.next.hasNext then
    .success it it.next.curr
  else
    .success it none

@[inherit_doc peek2?, inline]
def peek2! : Parsec Char := do
  let some c ← peek2? | fail unexpectedEndOfInput
  return c

/-- Parse the content of a comment excluding the initial '#'.
`f` is a character that should directly follow the '#'

TODO: Implement whitespace `f` instead of just `f = ' '`. -/
partial def commentCore (acc : String := "") (f : Char) : Parsec String := do
  let c ← peek!
  if c = '\n' then
    -- A comment can continue on the next line if that line starts with `#_` where `_`
    -- is the character `f`.
    skip
    ws
    let some c ← peek? | return acc
    if c = '#' then
      let c' ← peek2!
      if c' = f then
        -- Continue the comment which is stretched over multiple lines
        skip
        skip
        ws
        -- Separate new lines for refs & flags rather by comma.
        let sep := if f = ':' ∨ f = ',' then ',' else '\n'
        commentCore (acc.push sep) f
      else
        -- next line contains a different type of comment
        return acc
    else
      -- next line does not contain a comment
      return acc
  else
    let c ← anyChar
    if c = '\\' then
      commentCore (acc.push (← escapedChar)) f
    else
      commentCore (acc.push c) f

/-- Returns the content of a comment. -/
partial def commentAux (acc : POEntry) : Parsec POEntry := do
  -- This first character specifies the sort of comment, see po specification.
  let f ← anyChar
  if f = '\t' ∨ f = '\n' ∨ f = '\r' ∨ f = ' ' then
    -- whitespace
    ws
    let content ← commentCore (f := ' ')
    return { acc with comment := content }
  else if f = '.' then
    -- "extracted comment"
    skip
    ws
    let content ← commentCore (f := f)
    return { acc with extrComment := content}
  else if f = ':' then
    -- "references"
    skip
    ws
    let content ← commentCore (f := f)
    return { acc with ref := parseRefs content}
  else if f = ',' then
    -- "flags"
    skip
    ws
    let content ← commentCore (f := f)
    return { acc with flags := parseFlags content}
  else if f = '|' then
    -- "previous"
    skip
    ws
    skipString "msg"
    -- TODO: Need to strip quotes!
    let c ← peek!
      if c = 'i' then
        skipString "id"
        ws
        let content ← commentCore (f := f)
        return { acc with prevMsgId := content}
      else if c = 'c' then
        skipString "ctxt"
        ws
        let content ← commentCore (f := f)
        return { acc with prevMsgCtxt := content}
      else
        fail "expected `#| msgid ` or `#| msgctxt`."
  else
    fail "unexpected comment format."

/-- Parse an PO-entry.

Note: This assumes that there are no leading spaces on any lines. Is that fine? -/
partial def parseEntry (acc : Option POEntry := none) : Parsec POEntry := do
  let acc : POEntry := match acc with
  | some acc => acc
  | none => { msgId := "" }

  let some c ← peek? | return acc

  if c = '#' then
    skip
    let newAcc ← commentAux acc
    parseEntry newAcc
  else if c = 'm' then
    skipString "msg"
    let c ← peek!
    if c == 'i' then
      skipString "id"
      ws
      skipString "\""
      let newAcc : POEntry := { acc with msgId := (← strCore) }
      parseEntry newAcc
    else if c == 's' then
      skipString "str"
      ws
      skipString "\""
      let newAcc : POEntry := { acc with msgStr := (← strCore) }
      parseEntry newAcc
    else if c == 'c' then
      skipString "ctxt"
      ws
      skipString "\""
      let newAcc : POEntry := { acc with msgCtxt := (← strCore) }
      parseEntry newAcc
    else
      fail "unexpected input, expected: `msgid`/`msgstr`/`msgctxt`"
  else
    return acc

/-- Core for `I18n.POFile.Parser.parseFile` -/
partial def parseFileCore (entries : Array POEntry := #[]) (header : Option POHeaderEntry := none) :
    Parsec POFile := do
  ws
  match (← peek?) with
  | some _ =>
    let entry ← parseEntry
    if entry.msgCtxt == none ∧ entry.msgId == "" then
      -- TODO: parse header
      let h : POHeaderEntry := {
        projectIdVersion  := ""
        reportMsgidBugsTo := ""
        potCreationDate   := ""
        language          := "" }
      parseFileCore entries (header := h)
    else
      parseFileCore (entries.push entry) (header := header)
  | none =>
    let header : POHeaderEntry := match header with
    | some h => h
    | none => {
        projectIdVersion  := ""
        reportMsgidBugsTo := ""
        potCreationDate   := ""
        language          := "" }
    return {entries := entries, header := header}

/-- Parsec parser for PO files. -/
def parseFile : Parsec POFile := do
  ws
  let res ← parseFileCore
  eof
  return res

end Parser

/-- Parse the content of a PO file. -/
def parse (s : String) : Except String POFile :=
  match POFile.Parser.parseFile s.mkIterator with
  | Parsec.ParseResult.success _ res => Except.ok res
  | Parsec.ParseResult.error it err  => Except.error s!"offset {repr it.i.byteIdx}: {err}"

end POFile

open System

/-- Read a PO file and parse it. -/
def POFile.read (path : FilePath) : IO <| POFile := do
  if ¬ (← FilePath.pathExists path) then
    panic "File does not exist!"
  let content ← IO.FS.readFile path
  match POFile.parse content with
  | .ok f =>
    return f
  | .error err =>
    panic! s!"Failed to parse PO file: {err}"
