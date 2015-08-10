Codepagex
=========

An elixir library to convert between codepages for strings.


All the mappings are fetched from unicode.org tables and conversion functions
are generated from these.

_Demo quality_

## Examples

The package is assumed to be interfaced using the `Codepagex` module.

```elixir
iex> Codepagex.from_string :iso_8859_1, "Hello æøåÆØÅ!"
{:ok, <<72, 101, 108, 108, 111, 32, 230, 248, 229, 198, 216, 197, 33>>}

iex> Codepagex.to_string :iso_8859_1, <<72, 101, 108, 108, 111, 32, 230, 248,
...> 229, 198, 216, 197, 33>>
{:ok, "Hello æøåÆØÅ!"}
```

## Encodings

A full list of encodings is found by running `Codepagex.list_mappings`. 

The mappings are best supplied as an atom, or else the string is converted to
atom for you (but with a somewhat less efficient function lookup). Eg:

```elixir
iex> Codepagex.from_string :"VENDORS/MICSFT/MAC/TURKISH", "æøå"
{:ok, <<190, 191, 140>>}
```

For some encodings, an alias is set up for easier dispatch. The list of aliases
is found by running `Codepagex.aliases`. The code looks like: 

```elixir
iex> Codepagex.from_string! :iso_8859_1, "Hello æøåÆØÅ!"
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

