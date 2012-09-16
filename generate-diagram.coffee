graphviz = require 'graphviz'
wildcard = require 'wildcard'
_ = require 'underscore'

startsWith = (string, prefix) -> string.indexOf(prefix) is 0

exports = module.exports = (nodes, styles) ->

	# Make graph
	g = graphviz.digraph "G"

	# Add graph nodes
	for x, node of nodes
		node.graphNode = g.addNode node.name
		node.graphNode.set "fillcolor", "white"
		node.graphNode.set "style", "filled"
		for [pattern, key, value] in styles
			node.graphNode.set key, value if wildcard(pattern, node.name)

	# Add edges between nodes
	for x, node of nodes
		for dependency in node.dependencies
			if nodes[dependency]?
				edge = g.addEdge node.graphNode, nodes[dependency].graphNode, { dir: "forward" }
				if dependency in node.inheritances
					edge.set "style", "dashed"
					edge.set "arrowhead", "empty"

	# Return graph
	return g