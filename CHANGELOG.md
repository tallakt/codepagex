# Changelog

## 0.2.0 (2026-10-09)

### Changes that may affect existing code

- `:ascii` is now plain US-ASCII, where every byte 0..127 maps to the same
  codepoint. It used to be an alias for `"VENDORS/MISC/US-ASCII-QUOTES"`, which
  maps `'` and `` ` `` to the curly quotes U+2019 and U+2018. To keep the old
  behavior, add `"VENDORS/MISC/US-ASCII-QUOTES"` to `:encodings` and use that
  name.
- `to_string/4` and `from_string/4` now return `{:error, reason, acc}` when the
  outer `missing_fun` returns `{:error, reason}`. Previously the 2-tuple was
  returned as it was, contradicting the typespec. Code that matched
  `{:error, reason}` on that result must be updated.
- `Codepagex.Error` now always has a string message. A reason that is not a
  string is converted with `inspect/1`. Before, `Exception.message/1` raised
  for such exceptions.
- Encoding CP932 now uses the standard byte sequences for the 23 codepoints
  that have several, for example U+2252 is `81E0` and not the NEC duplicate
  `8790`. Decoding is unchanged.
- The alias `:iso_8859_12` is removed. It never worked, as there is no ISO
  8859-12 mapping.
- An entry in `config :codepagex, :encodings` that matches no encoding now
  gives a compile time warning. Such entries used to be ignored silently.
  Projects compiled with `--warnings-as-errors` will fail on a mistyped entry.

### Fixes

- `replace_nonexistent/1` no longer crashes with `FunctionClauseError` on input
  that is not valid UTF-8. Each invalid byte is replaced.
- `to_string!/4` and `from_string!/4` raise `Codepagex.Error` when the outer
  `missing_fun` fails, instead of `CaseClauseError`.
- An `ArgumentError` raised inside a `missing_fun` is no longer reported as
  `Unknown encoding` when the encoding is given as a string.
- Which encodings are compiled no longer depends on where the project is
  located on disk. A path containing for example `next`, `readme` or `unicode`
  could result in no encodings, or wrong encoding names.
- The test configuration and the README example used the encoding names
  `MISC/CP424` and `MISC/CP856`, which do not exist. The names are
  `VENDORS/MISC/CP424` and `VENDORS/MISC/CP856`.
- Typespecs corrected: the accumulator is any term and not an integer, the
  inner `missing_fun` returns `{:error, reason, acc}`, and the argument and
  return types of `from_string/4`.
- Benchmarks: the 1M ISO8859-1 input was about 42 times too large, and some
  results were labeled `from_string` when `to_string` was measured. The Benchee
  task no longer keeps all results in memory.

### Other

- Continuous integration moved from Travis CI to GitHub Actions, testing
  Elixir 1.16 to 1.20 with Erlang/OTP 24 to 29, and running format checking,
  Credo and Dialyzer.
- README documents how regexes in `:encodings` behave on Erlang/OTP 28.
