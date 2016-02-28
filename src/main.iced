
fs = require 'fs'
{Parser} = require './parser'
minimist = require 'minimist'
{make_esc} = require 'iced-error'
colors = require 'colors'
astmod = require './ast'
pathmod = require 'path'

#================================================

usage = () ->
  console.error """usage:
    single file: avd2ljson [-2] -i <infile> -o <outfile>
    batch:       avd2ljson [-2] -b -o <outdir> <infiles...>
"""

#================================================

class Stack
  constructor : (@d) ->
    @d or= {}
  push : (nm) ->
    ret = {}
    for k,v of @d
      ret[k] = v
    ret[nm] = true
    return new Stack ret
  lookup : (nm) -> @d[nm]

#================================================

exports.FileRunner = class FileRunner

  #---------------

  constructor : ({@infile, @stack, @dir, @version}) ->
    @stack or= new Stack

  #---------------

  get_infile : () ->
    ret = pathmod.join @dir, @infile
    return ret

  #---------------

  open_infile : (opts, cb) ->
    esc = make_esc cb, "open_infile"
    await fs.readFile @get_infile(), esc defer dat
    cb null, dat.toString('utf8')

  #---------------

  parse : ({dat}, cb) ->
    parser = new Parser()
    parser.yy = astmod
    if @version is 2 then parser.yy.Protocol = astmod.ProtocolV2
    ast = null
    try
      ast = parser.parse dat
    catch e
      err = new Error("Parse error in: " + @infile + ": " + e.message)
    cb err, ast

  #---------------

  recurse : ({ast}, cb) ->
    esc = make_esc cb, "recurse"
    err = null
    for i in ast.get_imports()
      if @stack.lookup (nm = i.get_path().eval_to_string())
        err = new Error "import cycle found with '#{nm}'"
        break
      p = new FileRunner { infile : nm, stack : @stack.push(nm), @dir}
      await p.run {}, esc defer ast
      i.set_protocol ast
    cb err

  #---------------

  run : (opts, cb) ->
    esc = make_esc cb, "run"
    await @open_infile {}, esc defer dat
    await @parse { dat }, esc defer ast
    await @recurse { ast }, esc defer() unless (@version is 2)
    cb null, ast

#================================================

exports.parse = parse = ({infile, version }, cb) ->
  p = new FileRunner { infile : pathmod.basename(infile), dir : pathmod.dirname(infile), version }
  await p.run {}, defer err, ast
  cb err, ast

#================================================

exports.output = output = ({ast, outfile}, cb) ->
  json = ast.to_json()
  await fs.writeFile outfile, JSON.stringify(json, null, 2), defer err
  cb err

#================================================

exports.Main = class Main

  #---------------

  constructor : () ->
    @version = 1

  #---------------

  parse_argv : ({argv}, cb) ->
    argv = minimist argv
    if argv.h
      usage()
      err = new Error "usage: shown!"
    else if (@batch = argv.b)
      @outdir = argv.o
      @infiles = argv._
      @forcefiles = {}
      (@forcefiles[f] = true for f in argv.f)
      unless @outdir? and @infiles.length
        err = new Error "need an [-o <outdir>] and input files in batch mode"
    else
      @outfile = argv.o
      @infile = argv.i
      unless @outfile? and @infile?
        err = new Error "need an [-i <infile>] and a [-o <outfile>]"
    @version = if argv["2"] then 2 else 1
    cb err

  #---------------

  make_outfile : (f) -> pathmod.join @outdir, ((pathmod.basename f, '.avdl') + ".json")

  #---------------

  skip_infile : ({infile, outfile}, cb) ->
    esc = make_esc cb, "skip_infile"
    await
      fs.stat infile,  esc defer s0
      fs.stat outfile, defer err, s1
    cb null, (not(err?) and (s0.mtime <= s1.mtime))

  #---------------

  do_batch_mode : (opts, cb) ->
    esc = make_esc cb, "do_batch_mode"
    for f in @infiles
      outfile = @make_outfile f
      await parse { infile : f, @version }, esc defer ast
      if ast.has_messages() or @forcefiles[f] or (@version is 2)
        await output { ast, outfile }, esc defer()
        console.log "Compiling #{f} -> #{outfile}"
    cb null

  #---------------

  main : ({argv}, cb) ->
    esc = make_esc cb, "main"
    await @parse_argv {argv}, esc defer()
    if @batch
      await @do_batch_mode {}, esc defer()
    else
      await parse { @infile, @version }, esc defer ast
      await output {ast, @outfile}, esc defer()
    cb null

#================================================

exports.main = () ->
  main = new Main
  await main.main { argv :process.argv[2...] }, defer err
  rc = 0
  if err?
    rc = -2
    console.error err.toString().red

  process.exit rc
