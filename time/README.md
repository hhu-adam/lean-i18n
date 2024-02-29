# Lean Time

Tiny package which interacts with the `C++` implementation concerning time.

## Usage

Require the package in your `lakefile.lean` and add `import Time` in your Lean file.

## Troubleshoot

If you get an error that `c++` is not found, you can double-check with `which c++ g++ gcc`
and then install `gcc` with:

```
sudo apt install build-essential
```

**Implemented Functions:**

- `Time.getLocalTime` returns the local date/time as a `String`.

## Note
You should use the [`datetime` library](https://github.com/T-Brick/DateTime) instead.
This remains here for now as a fallback option.
