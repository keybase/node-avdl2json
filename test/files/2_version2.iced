{parse} = require '../..'
fs = require 'fs'
pathmod = require 'path'

mkpath = (dir, file) -> pathmod.join __dirname, "..", dir, file

test_file = (T,nm,cb) ->
  await parse { infile : mkpath("avdl/v2", nm + ".avdl"), version : 2 }, T.esc(defer(dat), cb)
  out = mkpath("json/v2", nm + ".json")
  await fs.readFile out, T.esc(defer(out_dat), cb)
  dat2 = JSON.parse out_dat
  T.equal dat.to_json(), dat2, "equality of output"
  T.waypoint nm
  cb null

exports.test_keybase_files = (T,cb) ->
  files = [
    "sample"
  ]
  for f in files
    await test_file T, f, T.esc(defer(), cb)

  cb()