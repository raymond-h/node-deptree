{EventEmitter} = require 'events'

module.exports = exports = ->
	tree = (name, extra) ->
		tree.extras[name] = extra
		new exports.Node tree, name

	tree.events = new EventEmitter
	tree.dependantTree = {}
	tree.extras = {}

	tree.update = (name) ->
		# emit 'update' event
		tree.events.emit 'update', name, tree.extras[name]

		# .update nodes that depend on ´name´ if any
		dependants = (tree.dependantTree[name] ?= [])
		tree.update d for d in dependants

	tree

class exports.Node
	constructor: (@tree, @name) ->

	dependsOn: (names...) ->
		(@tree.dependantTree[name] ?= []).push @name for name in names

		this

	on: (event, callback) ->
		@tree.events.on event, (name, a...) =>
			callback name, a... if name is @name