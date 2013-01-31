# THREE = require 'three'
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
