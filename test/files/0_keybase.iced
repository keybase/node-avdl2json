

{parse} = require '../..'
fs = require 'fs'
pathmod = require 'path'

mkpath = (dir, file) -> pathmod.join __dirname, "..", dir, file

test_file = (T,nm,cb) ->
  await parse { infile : mkpath("avdl", nm + ".avdl") }, T.esc(defer(dat), cb)
  out = mkpath("json", nm + ".json")
  await fs.readFile out, T.esc(defer(out_dat), cb)
  dat2 = JSON.parse out_dat
  T.equal dat.to_json(), dat2, "equality of output"
  T.waypoint nm
  cb null

exports.test_keybase_files = (T,cb) ->
  files = [
    "identify_ui"
    "account"
    "block"
    "btc"
    "config"
    "constants"
    "crypto"
    "ctl"
    "debugging"
    "delegate_ui_ctl"
    "device"
    "favorite"
    "gpg_ui"
    "identify"
    "install"
    "kbfs"
    "kex2provisioner"
    "kex2provisionee"
    "log"
    "log_ui"
    "login"
    "login_ui"
    "metadata"
    "metadata_update"
    "notify_ctl"
    "notify_fs"
    "notify_session"
    "notify_tracking"
    "notify_users"
    "pgp"
    "pgp_ui"
    "prove"
    "prove_ui"
    "provision_ui"
    "quota"
    "revoke"
    "saltpack"
    "saltpack_ui"
    "secretkeys"
    "secret_ui"
    "session"
    "signup"
    "sigs"
    "stream_ui"
    "test"
    "track"
    "ui"
    "update"
    "update_ui"
    "user"
  ]
  for f in files
    await test_file T, f, T.esc(defer(), cb)

  cb()