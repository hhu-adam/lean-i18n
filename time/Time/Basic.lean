import Lean

namespace Time

/-
TODO: see comment in lakefile about `c++`.
-/
-- /-- Returns the local date/time as a string. -/
-- @[extern "formatLocalTime"]
-- opaque getLocalTime : IO String

/-- Dummy implementation because FFI does not work for everybody. TODO: fix me. -/
def getLocalTime : IO String := do return ""
