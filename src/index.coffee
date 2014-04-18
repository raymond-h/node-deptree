{EventEmitter} = require 'events'

_ = require 'underscore'

module.exports = exports = (updater = 'linear') ->
	if typeof updater is 'string'
		updater = exports.defaultUpdaters[updater] ? exports.linearUpdater

	tree = (name, extra) ->
		tree.extras[name] = extra
		new exports.Node tree, name

	tree.events = new EventEmitter
	tree.dependentTree = {}
	tree.extras = {}
	tree.updateListeners = {}
	tree.updater = updater

	tree.update = (target, options..., callback) ->
		options = options[0] ? {}
		_.defaults options,
			triggerTarget: true

		triggerUpdate = (name, done) ->
			tree.events.emit 'update', name, tree.extras[name]

			async = -> (async = null; done)

			if options.triggerTarget or name isnt target
				tree.updateListeners[name]? name, tree.extras[name], async

			done() if async?

		updater tree, target, triggerUpdate, -> callback?()

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

	tree.checkDependsOn = (mainName, depName) ->
		mainName in tree.dependents depName

	tree

exports.defaultUpdaters = {}

exports.defaultUpdaters.linear =
exports.linearUpdater = (tree, name, triggerUpdate, done) ->
	queue = tree.buildUpdateQueue name

	do update = ->
		process.nextTick ->
			item = queue.shift()

			triggerUpdate item, ->
				if queue.length > 0 then update()
				else done()

exports.defaultUpdaters.parallel =
exports.parallelUpdater = (tree, name, triggerUpdate, done) ->
	treeMap = tree.buildUpdateTree name

	next = (nextName, callback) ->
		process.nextTick ->
			triggerUpdate nextName, ->
				updateDone nextName, callback
		
	updateDone = (name, callback) ->
		doNext = []
		for node, deps of treeMap when name in deps
			i = deps.indexOf name
			deps[i..i] = []

			doNext.push node if deps.length is 0

		return callback() if doNext.length is 0

		allDone = _.after doNext.length, callback
		for node in doNext
			next node, allDone

		null

	next name, ->
		done()

class exports.Node
	constructor: (@tree, @name) ->

	dependsOn: (names...) ->
		for name in names
			if @tree.checkDependsOn name, @name
				throw new Error "Circular dependency, #{name} already depends on #{@name}"

		(@tree.dependentTree[name] ?= []).push @name for name in names

		this

	onUpdate: (callback) ->
		@tree.updateListeners[@name] = callback