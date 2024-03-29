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
your project. To save them all to a template file, you have multiple options (choose one):

* Call `lake exe i18n --template` inside your project (after `lake build`).
* Place `#export_i18n` inside any Lean document. This will be executed every time that Lean
  document is built.
* call `I18n.createTemplate` at any suitable point in your (meta-) code.

Any of these options will create a file `.i18n/en/[YourProject].pot` which you can
translate using any a suitable editor like "Poedit" (these editors also help you merging a modified `.pot` into an existing translation).
The translated files should be saved as `.i18n/[lang]/[YourProject].po`.

Once you have a translation present, you can use `set_language` to translate everything
in the current document: e.g. set `set_language fr` at the top of your lean document and you
should get your French translation of strings printed.

## PO Files

This package aims to support PO files as specified
in the [GNU gettext manual](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html).

(currently no plural forms!)

If your third-party software can not import a PO-file or produces a PO-file which can't be parsed (correctly) in Lean,
please create a bug report here with a sample PO-file!

## Json Files

Currently the recommended workflow to retrieve i18next-compatible JSON files is the following:

1. use `lake exe i18n --template` to create a `.pot` file
2. create/manage the translated `.po` files as described above.
3. run `lake exe i18n --export-json`. This will export *every* `.po` file inside the `.i18n/` folder
   into a Json located in the same folder.

### Avoiding PO files

However, you might want to choose to avoid PO-files and exclusively manage the less expressive
Json files. In this case, you can set `"useJson": true` inside `.i18n/config.json`. With this
option the template will be `.i18n/en/[YourProject].json` and it will look for translations
at `.i18n/[lang]/[YourProject].json`

## Contribution

This is merely a prototype. Contributions are very welcome!

If you have a usage case for translations in Lean which isn't covered by this package,
please open an issue explaining how you would want to use translations in Lean!

## Credits

By Jon Eugster.

The project is inspired by a code snippet by Kyle Miller,
shared on [Zulip](https://leanprover.zulipchat.com).
