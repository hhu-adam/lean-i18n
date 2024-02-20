# Lean Internationalisation

This package provides internationalisation ("i18n") for Lean projects. It is
an (incomplete) reimplementation of the
[GNU gettext](https://www.gnu.org/software/gettext/manual/gettext.html)
utilities.

## Usage

Add the following line to your projects `lakefile.lean`:

```lean
require getText from git "TODO-ADD-CORRECT-URL" @ "main"
```

and call `lake update getText`
