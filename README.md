# Lean Internationalisation

This package provides internationalisation ("i18n") for Lean projects.

## Usage

Add the following line to your projects `lakefile.lean`:

```lean
require i18n from git "https://github.com/hhu-adam/lean-i18n" @ "main"
```

There are three options to mark strings for translation:

* `t!"…"`: works like `s!"…"`.
* `mt!"…"`: works like `m!"…"`.
* `String.translate`: to translate a string (meta code)

Marking strings with these three options will collect untranslated strings throughout
your project. To save them all to a PO-template file, you can call `#create_pot`, e.g. in your
project's main file.
(Alternatively you can call `I18n.createPOTemplate` at any suitable point in your (meta-) code.)

Both will create a file `.i18n/[yourProject].pot` which you can translate using any
"PO Editor". The translated files should be saved as `.i18n/[yourProject]-[lang].po`

Once you have a translation present, you can use `set_language` to translate everything
in the current document: e.g. set `set_language fr` at the top of your lean document and you should get
your French translation of strings printed.

## PO Files

This package aims to add support for PO files as specified
in the [GNU gettext manual](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html).

You can use existing "PO editors" to manage the translations. For example, they help with
merging an updated `.pot` file.

If your thirdparty software produces a PO-file which can't be parsed (correctly) in Lean,
please create a bug report here with a sample PO-file!

## Contribution

This is merely a prototype. Contributions are very welcome!

If you have a usage case for translations in Lean which isn't covered by this package,
please open an issue explaining how you would want to use translations in Lean!

## Credits

By Jon Eugster.

The project is inspired by a code snippet by Kyle Miller,
shared on [Zulip](https://leanprover.zulipchat.com).