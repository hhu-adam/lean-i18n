import I18n.PO.Write

open I18n

/--
info: { projectIdVersion := "i18n v4.22.0",
  reportMsgidBugsTo := "",
  potCreationDate := "2025-09-06",
  poRevisionDate := none,
  lastTranslator := "Jane Doe",
  languageTeam := some "none",
  language := "de",
  contentType := "text/plain; charset=UTF-8",
  contentTransferEncoding := "8bit",
  pluralForms := none }
-/
#guard_msgs in
#eval POEntry.toPOHeaderEntry {
  msgId := ""
  msgStr := "Project-Id-Version: i18n v4.22.0\nReport-Msgid-Bugs-To: \nPOT-Creation-Date: 2025-09-06\nLast-Translator: Jane Doe\nLanguage-Team: none\nLanguage: de\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: 8bit"
}
