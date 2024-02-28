# Lean Internationalisation

This package provides internationalisation ("i18n") for Lean projects.

## Usage

Add the following line to your projects `lakefile.lean`:

```lean
require i18n from git "TODO-ADD-CORRECT-URL" @ "main"
```

There are three options to mark strings for translation:

* `t!"…"`: works like `s!"…"`.
* `mt!"…"`: works like `m!"…"`.
* `String.translate`: to translate a string (meta code)

This will collect all untranslated strings in your project. To save all collected
untranslated strings into a PO-template file, you can call `CreatePOT` (e.g. in your
project's main file).

Alternatively you can call `createPOTemplate` at any point in your (meta-) code.

Both will create a file `.i18n/[yourProject].pot` which you can translate using any
"PO Editor". The translated files should be saved as `.i18n/[yourProject]-[lang].po`

Once you have a translation present, you can use `Language` to translate everything
in the current live: Set `Language fr` at the top of your lean document.

## PO Files

This package aims to add support for PO files as specified
in the [GNU gettext manual](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html).

You can use existing "PO editors" to manage the translations. For example, they help with
merging an updated `.pot` file.

If your software produces a Po-file which can't be parsed, please report a Bug here with a
sample PO-file!


## Contribution

This is merely a prototype. Contributions are very welcome!

If you have a usage case for translations which this package doesn't cover, please open an
issue explaining how you would want to use translations in Lean!

## Credits

By Jon Eugster.

The project is inspired by a code snippet by Kyle Miller,
shared on [Zulip](https://leanprover.zulipchat.com).