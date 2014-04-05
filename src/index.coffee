{EventEmitter} = require 'events'

Q = require 'q'

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

	tree.dependencies = (name) ->
		key for key, value of tree.dependantTree when name in value

	tree.buildUpdateQueue = (name) ->
		queue = [name]

		addDeps = (name) ->
			dependants = (tree.dependantTree[name] ?= [])
			for d in dependants when not (d in queue)
				queue.push d
				addDeps d

		addDeps name

		queue

	tree.buildUpdateTree = (name, treeMap = {}) ->

	tree

class exports.Node
	constructor: (@tree, @name) ->

	dependsOn: (names...) ->
		(@tree.dependantTree[name] ?= []).push @name for name in names

		this

	on: (event, callback) ->
		@tree.events.on event, (name, a...) =>
			callback name, a... if name is @name