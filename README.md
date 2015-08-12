Codepagex
=========

[![Build Status](https://travis-ci.org/tallakt/codepagex.svg)](https://travis-ci.org/tallakt/codepagex)

An elixir library to convert between string encodings to and from utf-8. Like
iconv, but written in pure Elixir.


All the encodings are fetched from unicode.org tables and conversion functions
are generated from these.

Note that all unicode mapping files are processed during compilation, to that
part is slightly time consuming.

_Demo quality_

## Examples

The package is assumed to be interfaced using the `Codepagex` module.

```elixir
iex> Codepagex.from_string "Hello æøåÆØÅ!", :iso_8859_1
{:ok, <<72, 101, 108, 108, 111, 32, 230, 248, 229, 198, 216, 197, 33>>}

iex> Codepagex.to_string <<72, 101, 108, 108, 111, 32, 230, 248,
...> 229, 198, 216, 197, 33>>, :iso_8859_1
{:ok, "Hello æøåÆØÅ!"}
```

## Encodings

A full list of encodings is found by running `Codepagex.encoding_list/0`. 

The encodings are best supplied as an atom, or else the string is converted to
atom for you (but with a somewhat less efficient function lookup). Eg:

```elixir
iex> Codepagex.from_string "æøå", :"VENDORS/MICSFT/MAC/TURKISH"
{:ok, <<190, 191, 140>>}
```

For some encodings, an alias is set up for easier dispatch. The list of aliases
is found by running `Codepagex.aliases/0`. The code looks like: 

```elixir
iex> Codepagex.from_string! "Hello æøåÆØÅ!", :iso_8859_1
<<72, 101, 108, 108, 111, 32, 230, 248, 229, 198, 216, 197, 33>>
```

## Remaining work

- A few encodings are not yet supported for different reasons
- Optimize lookup so that a range with equal offset may be treated in one 
  pattern match
- Supply a function to deal with undefined characters
- select encodings in mix.exs
- a bunch of warnings about shadowed parameters durin compilation
- add specs
