# Lean Time

Tiny package which interacts with the `C++` implementation concerning time.

## Usage

Require the package in your `lakefile.lean` and add `import Time` in your Lean file.

**Implemented Functions:**

- `Time.getLocalTime` returns the local date/time as a `String`.

## Note
You should use the [`datetime` library](https://github.com/T-Brick/DateTime) instead.
This remains here for now as a fallback option.
