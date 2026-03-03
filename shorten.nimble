# Package

version       = "0.2.0"
author        = "Carlo Capocasa"
description   = "Minimal secure URL shortener"
license       = "MIT"
srcDir        = "src"
bin           = @["shortend", "shorten"]

# Dependencies

requires "nim >= 2.0.0"
requires "limdb"
requires "httpbeast#master"
requires "libsha"


