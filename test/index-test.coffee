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

	describe '#dependencies()', ->
		it 'should return the dependencies of the given node', ->
			tree 'A'
			.dependsOn 'B', 'C'

			tree 'B'
			.dependsOn 'G', 'Q'

			tree 'C'
			.dependsOn 'F'

			tree.dependencies('A').should.deep.equal ['B', 'C']
			tree.dependencies('B').should.deep.equal ['G', 'Q']
			tree.dependencies('C').should.deep.equal ['F']
			tree.dependencies('Q').should.deep.equal []

	describe '#dependents()', ->
		it 'should return the nodes depending on the given node', ->
			tree 'A'
			.dependsOn 'B', 'C'

			tree 'B'
			.dependsOn 'G', 'Q'

			tree 'C'
			.dependsOn 'F'

			tree.dependents('A').should.deep.equal []
			tree.dependents('B').should.deep.equal ['A']
			tree.dependents('C').should.deep.equal ['A']
			tree.dependents('Q').should.deep.equal ['B']

	describe '#buildUpdateQueue()', ->
		it 'should return an array of nodes in the order to update them in', ->
			tree 'A'
			.dependsOn 'B', 'C'

			tree 'B'
			.dependsOn 'G', 'Q'

			tree 'C'
			.dependsOn 'F'

			tree 'Q'
			.dependsOn 'C'

			tree.buildUpdateQueue 'F'
			.should.deep.equal ['F', 'C', 'A', 'Q', 'B']

			tree.buildUpdateQueue 'G'
			.should.deep.equal ['G', 'B', 'A']

			tree.buildUpdateQueue 'B'
			.should.deep.equal ['B', 'A']

	describe '#buildUpdateTree()', ->
		it 'should return a map of affected nodes mapped to their dependencies', ->
			tree 'A'
			.dependsOn 'B', 'C'

			tree 'B'
			.dependsOn 'G', 'Q'

			tree 'C'
			.dependsOn 'F'

			tree 'Q'
			.dependsOn 'C'

			tree.buildUpdateTree 'G'
			.should.deep.equal
				'G': []
				'B': ['G', 'Q']
				'A': ['B', 'C']

describe 'Node', ->
	describe '#dependsOn()', ->
		it 'should add one or more dependencies', ->
			tree 'A'
			.dependsOn 'B', 'C'

			tree.dependentTree.should.deep.equal { 'B': ['A'], 'C': ['A'] }

	describe '#on()', ->
		it 'should add an event handler for the given event', ->
			tree('A').on 'update', (name) ->

			tree.events.listeners('update').should.be.length 1