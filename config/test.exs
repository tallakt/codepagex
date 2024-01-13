import Config

config :codepagex, :encodings, [
    :ascii,
    ~r[iso8859]i,
    "ETSI/GSM0338",
    "MISC/CP424",
    :"MISC/CP856"
  ]
