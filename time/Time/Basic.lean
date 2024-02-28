import Lean

namespace Time

/-- Returns the local date/time as a string. -/
@[extern "formatLocalTime"]
opaque getLocalTime : IO String

