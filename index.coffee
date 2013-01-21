# THREE = require 'three'
stlParser = require './stl_parser'
binaryXHR = require 'binary-xhr'

# loads some geometry, calls callback with format:
#   (error, geometry) -> ...
@loadGeometry = (location, callback) ->

  if typeof location is 'string'
    binaryXHR location, (error, data) ->
      callback( error ) if error
      geometry = stlParser.parse( data )
      callback( null, geometry )

  else
    throw new Error "Dunno how to load geometry with location #{location} (#{typeof location})"

# Given a Three.js geometry centered at 'pos' in world coordinates and scaled by factor 'scale',
# return a flat layer of voxels at a plane at height 'y'
@voxelateLayer = (geometry, pos, scale, y) ->
