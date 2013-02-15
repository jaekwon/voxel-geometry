###
@author aleeper / http://adamleeper.com/
@author mrdoob / http://mrdoob.com/
@author jaekwon / http://kopimism.org/

Description: A THREE loader for STL files, as created by Solidworks and other CAD programs.
Limitations: The binary loader could be optimized for memory.
###

THREE = require 'three'

# Constructor for a singleton throwaway data structure...
Triangle = ->
  @_sa =0
  @_buffer = new ArrayBuffer(50)
  @__byte = new Uint8Array(@_buffer)
  @normal = new Float32Array(@_buffer, @_sa+0, 3)
  @v1 = new Float32Array(@_buffer, @_sa+12, 3)
  @v2 = new Float32Array(@_buffer, @_sa+24, 3)
  @v3 = new Float32Array(@_buffer, @_sa+36, 3)
  _attr = new Int16Array(@_buffer, @_sa+48, 1)
  Object.defineProperty(this, "attr",{
    get: -> _attr[0]
    set: (val) -> _attr[0] = val
    enumerable: true
  })

@parse = ( arrayBuffer ) ->
  u8a = new Uint8Array( arrayBuffer )
  head = String.fromCharCode.apply( null, new Uint8Array( arrayBuffer, 0, 5 ) )
  if head is 'solid'
    return parseAscii( u8a )
  else
    return parseBinary( u8a )

@parseBinary = parseBinary = ( u8a ) ->
  geometry = new THREE.Geometry()
  # Header
  # header = data[...80]
  # Num triangles
  numTriangles =  u8a[80] << 0
  numTriangles += u8a[81] << 8
  numTriangles += u8a[82] << 16
  numTriangles += u8a[83] << 24
  # console.log("Found #{numTriangles} triangles")
  face = new Triangle()
  offset = 84
  for i in [0...numTriangles]
    for j in [0...50]
      face.__byte[j] = u8a[offset+j]
    # Triangles
    geometry.vertices.push new THREE.Vector3(face.v1[0], face.v1[1], face.v1[2])
    geometry.vertices.push new THREE.Vector3(face.v2[0], face.v2[1], face.v2[2])
    geometry.vertices.push new THREE.Vector3(face.v3[0], face.v3[1], face.v3[2])
    # Normal
    normal = new THREE.Vector3(face.normal[0], face.normal[1], face.normal[2])
    len = geometry.vertices.length
    geometry.faces.push new THREE.Face3( len - 3, len - 2, len - 1, normal )
    offset += 50
  # Complete geometry data
  geometry.computeCentroids()
  geometry.computeBoundingSphere()
  geometry.computeFaceNormals()
  geometry.computeVertexNormals()
  # geometry.normalsNeedUpdate = true
  return geometry

@parseAscii = parseAscii = ( u8a ) ->

  idx = 0
  state = 'START'
  geometry = new THREE.Geometry()

  isBlank = -> String.fromCharCode( u8a[idx] ) in [' ', '\n', '\r']
  skipBlank = -> idx++ while isBlank() and idx < u8a.length
  readWord = (expected) ->
    skipBlank()
    s = ''
    while idx < u8a.length and not isBlank()
      s += String.fromCharCode( u8a[idx++] )
    skipBlank()
    throw new Error "Expected to read '#{expected}' but got '#{s}'" if expected? and expected isnt s
    return s
  peekWord = (expected) ->
    idx_bak = idx
    s = readWord()
    idx = idx_bak
    if expected?
      return s is expected
    else
      return s
  readNumber = ->
    n = readWord()
    return parseFloat(n)

  faces = 0

  `ScanBuffer: //` # a label, to break
  while idx < u8a.length

    switch state

      when 'START'
        readWord 'solid'
        name = readWord()
        state = 'FACET'
        continue

      when 'FACET'
        faces += 1
        if faces % 100 is 0
          console.log faces, idx
        readWord 'facet'
        readWord 'normal'
        normal = new THREE.Vector3( readNumber(), readNumber(), readNumber() )
        readWord 'outer'
        readWord 'loop'
        for i in [0...3]
          readWord 'vertex'
          geometry.vertices.push new THREE.Vector3( readNumber(), readNumber(), readNumber() )
        readWord 'endloop'
        readWord 'endfacet'

        len = geometry.vertices.length
        geometry.faces.push new THREE.Face3( len - 3, len - 2, len - 1, normal )

        state = 'END' if peekWord('endsolid')
        continue

      when 'END' then `break ScanBuffer;`

      else throw new Error "Unexpected state #{state}"

  throw new Error "WTF, state should have been END but was #{state}" unless state is 'END'

  # Complete geometry data
  geometry.computeCentroids()
  geometry.computeBoundingSphere()
  geometry.computeFaceNormals()
  geometry.computeVertexNormals()
  return geometry
