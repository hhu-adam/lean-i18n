import I18n.PO.Definition
import I18n.PO.Read
import I18n.PO.ToString
import I18n.PO.Write

namespace I18n

open Lake

open Lean.Elab.Command in


-- Bug: Introduces too many \n
def poToJson (path : FilePath) (out : FilePath) : CommandElabM Unit := do
  let po ← POFile.read path
  po.saveAsJson out
