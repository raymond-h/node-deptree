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

		target = [].concat target

		triggerUpdate = (name, done) ->
			tree.events.emit 'update', name, tree.extras[name]

			async = -> (async = null; done)

			if options.triggerTarget or not (name in target)
				tree.updateListeners[name]? name, tree.extras[name], async

			done() if async?

		updater tree, target, triggerUpdate, -> callback?()

	tree.dependencies = (name) ->
		key for key, value of tree.dependentTree when name in value

	tree.dependents = (name) ->
		tree.dependentTree[name] ? []

	tree.buildUpdateQueue = (names) ->
		queue = []
		names = [].concat names
		names.sort (a, b) ->
			if tree.checkDependsOn a, b then 1
			else if tree.checkDependsOn b, a then -1
			else 0

		addDeps = (name) ->
			if name in queue
				i = queue.indexOf name
				queue[i..i] = []

			queue.push name
			dependents = tree.dependents name
			for d in dependents
				addDeps d

		addDeps name for name in names

		queue

	tree.buildUpdateTree = (names) ->
		treeMap = {}
		names = [].concat names

		next = (name) ->
			deps = tree.dependents name
			treeMap[name] = deps
			next d for d in deps

		next name for name in names

		inverted = {}
		inverted[name] = [] for name in names
		for name, deps of treeMap
			for dep in deps
				(inverted[dep] ?= []).push name

		inverted

	tree.checkDependsOn = (mainName, depName) ->
		deps = tree.dependents depName
		while deps.length > 0
			return true if mainName in deps

			newDeps = []
			newDeps.push (tree.dependents depName)... for depName in deps
			deps = newDeps

		return false

	tree

exports.defaultUpdaters = {}

exports.defaultUpdaters.linear =
exports.linearUpdater = (tree, names, triggerUpdate, done) ->
	queue = tree.buildUpdateQueue names

	do update = ->
		process.nextTick ->
			item = queue.shift()

			triggerUpdate item, ->
				if queue.length > 0 then update()
				else done()

exports.defaultUpdaters.parallel =
exports.parallelUpdater = (tree, names, triggerUpdate, done) ->
	treeMap = tree.buildUpdateTree names

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

	allDone = _.after names.length, -> done()

	next name, allDone for name in names

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