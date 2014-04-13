{EventEmitter} = require 'events'

_ = require 'underscore'
Q = require 'q'

module.exports = exports = (updater = 'linear') ->
	if typeof updater is 'string'
		updater = exports.defaultUpdaters[updater] ? exports.linearUpdater

	tree = (name, extra) ->
		tree.extras[name] = extra
		new exports.Node tree, name

	tree.events = new EventEmitter
	tree.dependentTree = {}
	tree.extras = {}
	tree.updater = updater

	tree.update = (name) ->
		triggerUpdate = (name, done) ->
			tree.events.emit 'update', name, tree.extras[name]
			done()

		updater tree, name, triggerUpdate, ->

	tree.dependencies = (name) ->
		key for key, value of tree.dependentTree when name in value

	tree.dependents = (name) ->
		tree.dependentTree[name] ? []

	tree.buildUpdateQueue = (name) ->
		queue = [name]

		addDeps = (name) ->
			dependents = tree.dependents name
			for d in dependents when not (d in queue)
				queue.push d
				addDeps d

		addDeps name

		queue

	tree.buildUpdateTree = (name) ->
		treeMap = {}

		next = (name) ->
			deps = tree.dependents name
			treeMap[name] = deps
			next d for d in deps

		next name

		inverted = {}
		inverted[name] = []
		for name, deps of treeMap
			for dep in deps
				(inverted[dep] ?= []).push name

		inverted

	tree

exports.defaultUpdaters = {}

exports.defaultUpdaters.linear =
exports.linearUpdater = (tree, name, triggerUpdate, done) ->
	queue = tree.buildUpdateQueue name

	do update = ->
		item = queue.shift()
		
		triggerUpdate item, ->
			if queue.length > 0 then update()
			else done()

exports.defaultUpdaters.parallel =
exports.parallelUpdater = (tree, name, triggerUpdate, done) ->
	treeMap = tree.buildUpdateTree name

	next = (name) ->
		triggerUpdate name, ->
			updateDone name
		
	updateDone = (name) ->
		for node, deps of treeMap when name in deps
			i = deps.indexOf name
			deps[i..i] = []

			if deps.length is 0
				next node

	next name

class exports.Node
	constructor: (@tree, @name) ->

	dependsOn: (names...) ->
		(@tree.dependentTree[name] ?= []).push @name for name in names

		this

	on: (event, callback) ->
		@tree.events.on event, (name, a...) =>
			callback name, a... if name is @name