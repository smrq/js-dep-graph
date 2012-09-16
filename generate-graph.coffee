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
	nodes = []
	sources = if options.sources.length > 0 then options.sources else modules

	console.log sources

	while (sources.length)
		mod = sources.shift()
		continue if dependencyGraph[mod]?
		continue if _(options.excludedPatterns).any (pattern) -> wildcard(pattern, mod)

		graphNode =
			name: mod
			dependencies: []
			inheritances: [] # not yet implemented
			notFound: false

		modPath = path.join options.directory, mod + ".js"
		if fs.existsSync modPath
			src = fs.readFileSync modPath
			dependencies = _(detective src).uniq()
			graphNode.dependencies = dependencies
			sources.push dependency for dependency in dependencies
		else
			graphNode.notFound = true

		nodes.push graphNode

	return nodes