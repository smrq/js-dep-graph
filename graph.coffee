_ = require 'underscore'
generateNodes = require './generate-nodes'
generateDiagram = require './generate-diagram'
{argv, showHelp} = require('optimist')
	.describe('h', 'Show this help information.')
	.alias('h', '?')
	.alias('h', 'help')
	.describe('s', 'Source modules to generate dependency graph for. This parameter may be specified multiple times to add multiple source modules to the graph. Supports wildcards.')
	.describe('d', 'Base directory for modules.')
	.describe('o', 'Output image filename.')
	.describe('traverse', 'Direction to traverse the dependency graph from the source modules. Valid options are down, up, both, full.')
	.default('traverse', 'down')
	.check((args) -> throw "Invalid option '#{args.traverse}' to parameter 'traverse'" if args.traverse not in ['down', 'up', 'both', 'full'])
	.describe('externals', 'Include module dependencies external to the full dependency graph. This will include excluded modules and modules which are not found in the base directory.')
	.describe('ex', 'Modules to exclude from the dependency graph. Supports wildcards.')
	.describe('style', 'Define styling for modules. Syntax is: module,key,value . Supports wildcards.')
	.describe('debug', 'Enable debug logging')
	.string(['s', 'd', 'o', 'ex', 'style', 'traverse'])
	.boolean(['h', 'externals', 'br', 'debug'])
	.wrap(80)

if argv.h
	showHelp()
	return

# Utility functions

normalizeSlashes = (string) -> string.replace(/\\/g, "/")                                  #"#Fix syntax highlighting for broken editors
replaceSlashes = (string, replacement) -> string.replace(/\//g, replacement)
asArray = (input) ->
	return [] unless input?
	return input if _.isArray(input)
	return [input]

# Argument parsing

options = {}
options.directory = normalizeSlashes(argv.d ? __dirname)
options.sources = (normalizeSlashes source for source in asArray(argv.s))
options.output = argv.o ? "graph.png"
options.excludedPatterns = asArray(argv.ex)
options.styles = (style.split(",") for style in asArray(argv.style))
options.debug = argv.debug
options.traverse = argv.traverse
options.externals = argv.externals

nodes = generateNodes options
g = generateDiagram nodes, options.styles
console.log g.to_dot() if options.debug
console.log "Writing to #{options.output}"
g.output "png", options.output