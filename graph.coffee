fs = require 'fs'
path = require 'path'
graphviz = require 'graphviz'
detective = require './browser-detective'

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

startsWith = (string, prefix) -> string.indexOf(prefix) is 0
replaceSlashes = (string, replacement) -> string.replace(/\//g, replacement)

# Argument parsing

dir = argv.d ? __dirname

sources = argv.s
sources = [ sources ] unless Array.isArray(sources)

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
	dependencies = detective src
	dependencyGraph[mod] = dependencies
	sources.push dependency for dependency in dependencies

console.dir dependencyGraph if argv.debug

# Generate visual graph
g = graphviz.digraph "G"

# Make graph nodes for all referenced modules
nodes = {}
for name, dependencies of dependencyGraph
	displayName = if breaks then replaceSlashes(name,"\\n") else name
	nodes[name] = g.addNode displayName
	nodes[name].set "fillcolor", "white"
	nodes[name].set "style", "filled"

	# Node styling
	for [prefix, key, value] in styles.prefixes
		nodes[name].set key, value if startsWith name, prefix
	for [dependency, key, value] in styles.dependencies
		nodes[name].set key, value if dependency in dependencies

# Add edges between nodes
for name, dependencies of dependencyGraph
	for dependency in dependencies
		edge = g.addEdge nodes[name], nodes[dependency], { dir: "forward" } if nodes[dependency]?

# Generate image
console.log g.to_dot() if argv.debug
g.output "png", output