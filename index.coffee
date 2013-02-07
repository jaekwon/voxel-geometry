stlParser = require './stl_parser'
binaryXHR = require 'binary-xhr'

# Loads an external geometry.
# Supported formats:
#   * STL ascii
#   * STL binary
#             
# location:   URL of file on the cloud
# callback:   (error, geometry) -> ...
@loadGeometry = (location, callback) ->

  if typeof location is 'string'
    binaryXHR location, (error, data) ->
      callback( error ) if error
      geometry = stlParser.parse( data )
      callback( null, geometry )

  else
    throw new Error "Dunno how to load geometry with location #{location} (#{typeof location})"

# Given a voxel.js game object and a mesh,
# voxelate the mesh into cubes in the game.
@voxelateMesh = (game, mesh) ->

  THREE = game.THREE
  minX = minY = minZ = maxX = maxY = maxZ = undefined
  cubeSize = game.cubeSize

  mesh.updateMatrixWorld()
  
  for vertex in mesh.geometry.vertices
    # find real world coordinates for this vertex...
    worldVertex = vertex.clone()
    mesh.localToWorld(worldVertex)
    if worldVertex.x < minX or minX is undefined
      minX = worldVertex.x
    if worldVertex.y < minY or minY is undefined
      minY = worldVertex.y
    if worldVertex.z < minZ or minZ is undefined
      minZ = worldVertex.z
    if worldVertex.x > maxX or maxX is undefined
      maxX = worldVertex.x
    if worldVertex.y > maxY or maxY is undefined
      maxY = worldVertex.y
    if worldVertex.z > maxZ or maxZ is undefined
      maxZ = worldVertex.z

  minXQ = Math.floor(minX/cubeSize)
  minYQ = Math.floor(minY/cubeSize)
  minZQ = Math.floor(minZ/cubeSize)
  maxXQ = Math.ceil(maxX/cubeSize)
  maxYQ = Math.ceil(maxY/cubeSize)
  maxZQ = Math.ceil(maxZ/cubeSize)

  jobs = []

  # For each layer of y
  for yQ in [minYQ...maxYQ]
    # console.log(minYQ, maxYQ, yQ)
    y = yQ * cubeSize
    # For each ray...
    for xQ in [minXQ...maxXQ]
      x = xQ * cubeSize
      start = new THREE.Vector3( x + cubeSize/2, y + cubeSize/2, minZ )
      end = new THREE.Vector3( x + cubeSize/2, y + cubeSize/2, maxZ )
      
      # for now, let's just draw a line for each ray.
      material = new THREE.LineBasicMaterial({color: 0xFFFFFF})
      geometry = new THREE.Geometry()
      geometry.vertices.push(start)
      geometry.vertices.push(end)
      line = new THREE.Line(geometry, material)
      game.scene.add(line)
      jobs.push {yQ, y, xQ, x, line, start, end}

  consumeJob = ->
    {yQ, y, xQ, x, line, start, end} = jobs.shift()
    game.scene.remove(line)
    # Find intersection btw raycaster and mesh object.
    raycaster = new THREE.Raycaster( start, new THREE.Vector3(0, 0, 1) )
    intersects = raycaster.intersectObject(mesh)
    if intersects.length > 0
      if intersects.length % 2 is 1
        # This shouldn't happen. hmm
        console.log("Intersects.length was an odd number. :(")
        return
      intersectZs = (intersect.point.z for intersect in intersects)
      intersectZQs = (Math.floor(intersectZ/cubeSize) for intersectZ in intersectZs)
      # console.log(intersectZQs)

      # Iterate over all blocks now...
      inside = no
      material = 1
      for zQ in [minZQ...maxZQ]
        z = zQ * cubeSize
        if intersectZQs.length == 0 or intersectZQs[0] > zQ
          if inside
            game.createBlock(new THREE.Vector3(x + cubeSize/2, y + cubeSize/2, z + cubeSize/2), material)
        else if intersectZQs[0] == zQ
          # drain intersects
          while intersectZQs[0] is zQ
            inside = not inside
            if inside
              # NOTE: may be redudant
              game.createBlock(new THREE.Vector3(x + cubeSize/2, y + cubeSize/2, z + cubeSize/2), material)
            intersectZs.shift()
            intersectZQs.shift()
        else
          console.log("Should not happen")

    if jobs.length > 0
      setTimeout consumeJob, 1000.0/60.0
    else
      game.scene.remove(mesh)

  consumeJob()
