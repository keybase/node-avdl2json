
fs = require 'fs'
{Parser} = require './parser'
minimist = require 'minimist'
{make_esc} = require 'iced-error'
colors = require 'colors'
astmod = require './ast'
pathmod = require 'path'

#================================================

usage = () ->
  console.error """usage: avd2ljson -i <infile> -o <outfile>"""

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

  constructor : ({@infile, @stack, @dir}) ->
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
    await @recurse { ast }, esc defer()
    cb null, ast

#================================================

exports.parse = parse = ({infile}, cb) ->
  p = new FileRunner { infile : pathmod.basename(infile), dir : pathmod.dirname(infile) }
  await p.run {}, defer err, ast
  cb err, ast

#================================================

exports.Main = class Main

  #---------------

  constructor : () ->

  #---------------

  parse_argv : ({argv}, cb) ->
    argv = minimist argv
    if argv.h
      usage()
      err = new Error "usage: shown!"
    else
      @outfile = argv.o
      @infile = argv.i
      unless @outfile? and @infile?
        err = new Error "need an [-i <infile>] and a [-o <outfile>]"
    cb err

  #---------------

  output : ({ast}, cb) ->
    json = ast.to_json()
    await fs.writeFile @outfile, JSON.stringify(json, null, 2), defer err
    cb err

  #---------------

  main : ({argv}, cb) ->
    esc = make_esc cb, "main"
    await @parse_argv {argv}, esc defer()
    await parse { @infile }, esc defer ast
    await @output {ast}, esc defer()
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
