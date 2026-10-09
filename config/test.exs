import Config

# Regexes are not serializable on OTP 28.1+ unless using the E modifier, which
# needs Elixir 1.19, so list the ISO8859 encodings by name. See README.
config :codepagex, :encodings, [
  :ascii,
  "ISO8859/8859-1",
  "ISO8859/8859-2",
  "ISO8859/8859-3",
  "ISO8859/8859-4",
  "ISO8859/8859-5",
  "ISO8859/8859-6",
  "ISO8859/8859-7",
  "ISO8859/8859-8",
  "ISO8859/8859-9",
  "ISO8859/8859-10",
  "ISO8859/8859-11",
  "ISO8859/8859-13",
  "ISO8859/8859-14",
  "ISO8859/8859-15",
  "ISO8859/8859-16",
  "ETSI/GSM0338",
  "MISC/CP424",
  :"MISC/CP856"
]
