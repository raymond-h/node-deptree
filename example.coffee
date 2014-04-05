deptree = require 'deptree'

tree = deptree()

tree 'A'
.dependsOn 'B', 'C'
.on 'update', ->
	console.log "Changing A!"

tree.update 'C'