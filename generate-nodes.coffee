fs = require 'fs'
path = require 'path'
glob = require 'glob'
wildcard = require 'wildcard'
_ = require 'underscore'
detective = require './browser-detective'

normalizeSlashes = (string) -> string.replace(/\\/g, "/")                                  #"#Fix syntax highlighting for broken editors

exports = module.exports = (options) ->

	# Get list of all modules in base directory
	modules = glob.sync "**/*.coffee", {cwd: options.directory}
	modules = (normalizeSlashes path.join(path.dirname(sourceFile), path.basename(sourceFile, ".coffee")) for sourceFile in modules)

	# Remove all excluded modules
	modules = _(modules).difference wildcard(pattern, modules) for pattern in options.excludedPatterns

	# Generate node dependency data
	nodes = {}
	for mod in modules
		modPath = path.join options.directory, mod + ".js"
		src = fs.readFileSync modPath
		nodes[mod] =
			name: mod
			dependencies: _(detective src).uniq()
			inheritances: [] # not yet implemented
			dependents: []

	# Generate reverse dependency information
	for x, node of nodes
		nodes[dependency]?.dependents.push node.name for dependency in node.dependencies

	# Perform traversal
	if options.sources.length > 0
		traverse = (sources, direction) ->
			traversedNodes = {}
			console.log traversedNodes
			recur = (sources) ->
				for source in sources when not traversedNodes[source]?
					do (node = nodes[source]) ->
						return unless node?
						traversedNodes[source] = node
						recur node.dependencies if direction in ["down", "full"]
						recur node.dependents if direction in ["up", "full"]
			recur sources
			traversedNodes

		if options.traverse is 'both'
			nodes = _.extend traverse(options.sources, "down"), traverse(options.sources, "up")
		else
			nodes = traverse(options.sources, options.traverse)

	return nodes