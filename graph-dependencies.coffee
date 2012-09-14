graphviz = require 'graphviz'

startsWith = (string, prefix) -> string.indexOf(prefix) is 0

exports = module.exports = (dependencyGraph, styles) ->

	# Generate visual graph
	g = graphviz.digraph "G"

	# Make graph nodes for all referenced modules
	nodes = {}
	for name, {dependencies, displayName} of dependencyGraph
		displayName ?= name
		nodes[name] = g.addNode displayName
		nodes[name].set "fillcolor", "white"
		nodes[name].set "style", "filled"

		# Node styling
		for [prefix, key, value] in styles.prefixes
			nodes[name].set key, value if startsWith name, prefix
		for [dependency, key, value] in styles.dependencies
			nodes[name].set key, value if dependency in dependencies

	# Add edges between nodes
	for name, {dependencies, inheritances} of dependencyGraph
		for dependency in dependencies
			if nodes[dependency]?
				edge = g.addEdge nodes[name], nodes[dependency], { dir: "forward" }
				if dependency in inheritances
					edge.set "style", "dashed"
					edge.set "arrowhead", "empty"

	# Return graph
	return g