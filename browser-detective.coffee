# browser-detective
# Fork of substack/node-detective that supports RequireJS require() and define() calls
# instead of Node require()s.
#
# Original code:
# https://github.com/substack/node-detective

esprima = require("esprima")

traverse = (node, cb) ->
  if Array.isArray(node)
    node.forEach (x) ->
      traverse x, cb
  else if node and typeof node is "object"
    cb node
    Object.keys(node).forEach (key) ->
      traverse node[key], cb

walk = (src, cb) ->
  ast = esprima.parse(src)
  traverse ast, cb

walkSlow = (src, cb) ->
  ast = esprima.parse(src, {range: true})
  traverse ast, cb

exports = module.exports = (src, opts) ->
  exports.find(src, opts).strings

exports.find = (src, opts) ->
  isRequire = (node) ->
    node.type is "CallExpression" and node.callee.type is "Identifier" and node.callee.name in words
  opts = {} unless opts
  words = opts.words ? ["require", "define"]
  src = String(src) unless typeof src is "string"
  modules =
    strings: []
    expressions: []

  return modules if words.every (word) -> src.indexOf(word) is -1
  slowPass = false
  walk src, (node) ->
    return unless isRequire(node)
    if node.arguments.length and node.arguments[0].type is "Literal"
      modules.strings.push node.arguments[0].value
    else
      if node.arguments.length and node.arguments[0].type is "ArrayExpression"
        node.arguments[0].elements.forEach (x) ->
          if x.type is "Literal"
            modules.strings.push x.value
          else
            slowPass = true
      else
        slowPass = true

  if slowPass
    walkSlow src, (node) ->
      return unless isRequire(node)
      return unless node.arguments.length
      if node.arguments[0].type is "ArrayExpression"
        node.arguments[0].elements.forEach (x) ->
          r = x.range
          s = src.slice(r[0], r[1] + 1)
          modules.expressions.push s
      else
        unless node.arguments[0].type is "Literal"
          r = node.arguments[0].range
          s = src.slice(r[0], r[1] + 1)
          modules.expressions.push s
  modules
