chai = require 'chai'
{asyncCatch} = require './common'

{expect} = chai
chai.should()

deptree = require '../src/index'
tree = null

beforeEach ->
	tree = deptree()

describe 'Dependency tree', ->
	describe '#()', ->
		it 'should return an temporary node object
		    when given a string node name', ->

			node = tree 'A'

			expect(node).to.exist

			node.should.be.instanceof deptree.Node

		it 'should optionally take a second parameter
		    to be passed when the update event is emitted', (done) ->

			node = tree 'A', { 'candy': 'yes!' }

			tree.extras.should.deep.equal { 'A': { 'candy': 'yes!' } }

			node.on 'update', asyncCatch(done) (name, extra) ->
				extra.should.deep.equal { 'candy': 'yes!' }

				done()

			tree.update 'A'

	describe '#update()', ->
		it "should trigger update event for an updated node", (done) ->
			tree 'A'
			.on 'update', (name) ->
				name.should.equal 'A'

				done()

			tree.update 'A'

		it 'should trigger update event for dependencies before itself', (done) ->
			updatedB = false

			tree 'B'
			.on 'update', (name) ->
				updatedB = true

			tree 'A'
			.dependsOn 'B'
			.on 'update', asyncCatch(done) (name) ->
				updatedB.should.equal true, 'expected B to be updated before A'

				done()

			tree.update 'B'

describe 'Node', ->
	describe '#dependsOn()', ->
		it 'should add one or more dependencies', ->
			tree 'A'
			.dependsOn 'B', 'C'

			tree.dependantTree.should.deep.equal { 'B': ['A'], 'C': ['A'] }

	describe '#on()', ->
		it 'should add an event handler for the given event', ->
			tree('A').on 'update', (name) ->

			tree.events.listeners('update').should.be.length 1