fs = require 'fs'
path = require 'path'
graphviz = require 'graphviz'
detective = require './browser-detective'
graphdependencies = require './graph-dependencies'

{argv} = require('optimist')
	.demand('s')
	.describe('s', 'Source modules to generate dependency graph for. This parameter may be specified multiple times to add multiple source modules to the graph.')
	.describe('d', 'Base directory')
	.describe('o', 'Output image filename.')
	.describe('ex', 'Modules to exclude from the dependency graph')
	.describe('prefix', 'Define styling for module prefixes. Syntax is: prefix,key,value')
	.describe('depend', 'Define styling for module dependencies. Syntax is: name/of/module,key,value')
	.describe('include-depend', 'Do not exclude modules with defined dependency styling. Default is to exclude modules when they have an associated style.')
	.describe('br', 'Convert module namespaces into line breaks')
	.describe('debug', 'Enable debug logging')
	.wrap(80)

# Utility functions

normalizeSlashes = (string) -> string.replace(/\\/g, "/")                                  #"#Fix syntax highlighting for broken editors
replaceSlashes = (string, replacement) -> string.replace(/\//g, replacement)
unique = (collection) ->
	newCollection = []
	for item in collection
		newCollection.push item unless item in newCollection
	newCollection

# Argument parsing

dir = argv.d ? __dirname

sources = argv.s
sources = [ sources ] unless Array.isArray(sources)
sources = (normalizeSlashes(source) for source in sources)

output = argv.o ? replaceSlashes(sources[0],"-") + ".png"

excludedModules = argv.ex ? []
excludedModules = [ excludedModules ] unless Array.isArray(excludedModules)

styles = {}
styles.prefixes = argv.prefix ? []
styles.prefixes = [styles.prefixes] unless Array.isArray(styles.prefixes)
styles.prefixes[i] = prefix.split(",") for prefix, i in styles.prefixes
styles.dependencies = argv.depend ? []
styles.dependencies = [styles.dependencies] unless Array.isArray(styles.dependencies)
styles.dependencies[i] = dependency.split(",") for dependency, i in styles.dependencies

breaks = argv.br

unless argv['include-depend']
	excludedModules.push dependency[0] for dependency in styles.dependencies

# Generate dependency graph
dependencyGraph = {}
while (sources.length)
	mod = sources.shift()
	continue if dependencyGraph[mod]?
	continue if mod in excludedModules
	src = fs.readFileSync path.join dir, mod + ".js"
	dependencies = unique detective src
	inheritances = []
	dependencyGraph[mod] = {
		dependencies
		inheritances
		displayName: if breaks then replaceSlashes(mod,"\\n") else mod
	}
	for dependency in dependencies
		sources.push dependency unless dependency is "require"

console.dir dependencyGraph if argv.debug

g = graphdependencies dependencyGraph, styles
console.log g.to_dot() if argv.debug

console.log "Writing to #{output}"
g.output "png", output