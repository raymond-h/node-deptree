{EventEmitter} = require 'events'

_ = require 'underscore'
Q = require 'q'

module.exports = exports = ->
	tree = (name, extra) ->
		tree.extras[name] = extra
		new exports.Node tree, name

	tree.events = new EventEmitter
	tree.dependentTree = {}
	tree.extras = {}

	tree.update = (name) ->
		# emit 'update' event
		tree.events.emit 'update', name, tree.extras[name]

		# .update nodes that depend on ´name´ if any
		dependents = (tree.dependentTree[name] ?= [])
		tree.update d for d in dependents

	tree.dependencies = (name) ->
		key for key, value of tree.dependentTree when name in value

	tree.dependents = (name) ->
		tree.dependentTree[name] ? []

	tree.buildUpdateQueue = (name) ->
		queue = [name]

		addDeps = (name) ->
			dependents = (tree.dependentTree[name] ?= [])
			for d in dependents when not (d in queue)
				queue.push d
				addDeps d

		addDeps name

		queue

	tree.buildUpdateTree = (name, treeMap = {}) ->
		deps = tree.dependencies name
		treeMap[name] = deps
		for d in (tree.dependentTree[name] ?= [])
			tree.buildUpdateTree d, treeMap

		treeMap

	tree

class exports.Node
	constructor: (@tree, @name) ->

	dependsOn: (names...) ->
		(@tree.dependentTree[name] ?= []).push @name for name in names

		this

	on: (event, callback) ->
		@tree.events.on event, (name, a...) =>
			callback name, a... if name is @name