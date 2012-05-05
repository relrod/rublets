# Extra languages for Rublets-Stats.
# Keep alphabetical.

require "language_sniffer"

# @boredomist's Arroyo language
LanguageSniffer::Language.create(
  :name => 'Arroyo',
  :extensions => ['.arr'],
)

# Clay
LanguageSniffer::Language.create(
  :name => 'Clay',
  :extensions => ['.clay'],
)

# Forth
LanguageSniffer::Language.create(
  :name => 'Forth',
  :extensions => ['.forth'],
)

# Frink
LanguageSniffer::Language.create(
  :name => 'Frink',
  :extensions => ['.frink'],
)

# LOLCODE
LanguageSniffer::Language.create(
  :name => 'LOLCODE',
  :extensions => ['.lol'],
)

# Maxima
LanguageSniffer::Language.create(
  :name => 'Maxima',
  :extensions => ['.maxima'],
)

# @programble's Perpetual language
LanguageSniffer::Language.create(
  :name => 'Perpetual',
  :extensions => ['.perp'],
)

# SQLite
LanguageSniffer::Language.create(
  :name => 'SQLite',
  :extensions => ['.sqlite'],
)
