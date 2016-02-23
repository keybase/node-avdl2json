
fs = require 'fs'
{parser,Parser} = require './parser'
minimist = require 'minimist'
{make_esc} = require 'iced-error'
colors = require 'colors'
ast = require './ast'

#================================================

usage = () ->
  console.error """usage: avd2ljson -i <infile> -o <outfile>"""

#================================================

class Runner

  #---------------

  constructor : () ->

  #---------------

  parse_argv : ({argv}, cb) ->
    argv = minimist argv
    if argv.h
      usage()
      err = new Error "usage: shown!"
    else
      console.log argv
      @outfile = argv.o
      @infile = argv.i
      unless @outfile? and @infile?
        err = new Error "need an [-i <infile>] and a [-o <outfile>]"
    cb err

  #---------------

  open_infile : (opts, cb) ->
    await fs.readFile @infile, defer err, dat
    cb err, dat.toString('utf8')

  #---------------

  parse : ({dat}, cb) ->
    # parser = new Parser()
    parser.yy = ast
    try
      res = parser.parse dat
      console.log parser.yy.output
      @ast = parser.yy.output
    catch e
      err = new Error("Parse error in: " + @infile + ": " + e.message)
    cb err

  #---------------

  output : (opts, cb) ->
    console.log @ast
    cb null

  #---------------

  main : ({argv}, cb) ->
    esc = make_esc cb, "main"
    await @parse_argv {argv}, esc defer()
    await @open_infile {}, esc defer dat
    await @parse {dat}, esc defer()
    await @output {}, esc defer()
    cb null

#================================================

exports.main = () ->
  runner = new Runner
  await runner.main { argv :process.argv[2...] }, defer err
  rc = 0
  if err?
    rc = -2
    console.error err.toString().red

  process.exit rc
