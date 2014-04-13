deptree = require 'deptree'

tree = deptree()

tree 'A'
.dependsOn 'B', 'C'
.onUpdate ->
	console.log "Changing A!"

tree.update 'C'