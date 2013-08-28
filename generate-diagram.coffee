graphviz = require 'graphviz'
_ = require 'underscore'

startsWith = (string, prefix) -> string.indexOf(prefix) is 0

exports = module.exports = (nodes, options) ->

	# Make graph
	g = graphviz.digraph "G"

	# Graph-wide styling
	if options.neat
		g.set 'layout', 'neato'
		g.set 'overlap', false
		g.set 'splines', true
	if options.random
		g.set 'start', 'random'

	# Add graph nodes
	for name, node of nodes
		node.graphNode = g.addNode node.name
		node.graphNode.set "fillcolor", "white"
		node.graphNode.set "style", "filled"
		for [pattern, key, value] in options.styles
			node.graphNode.set key, value if pattern.test(name)

	# Add edges between nodes
	for name, node of nodes
		for dependency in node.dependencies
			if nodes[dependency]?
				edge = g.addEdge node.graphNode, nodes[dependency].graphNode, { dir: "forward" }
				if dependency in node.inheritances
					edge.set "style", "dashed"
					edge.set "arrowhead", "empty"

	# Return graph
	return g