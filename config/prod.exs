use Mix.Config

# Only have iso-xxx and ascii as standard for fast compilation
config :codepagex, :encodings, [:ascii, ~r[iso8859]i]
