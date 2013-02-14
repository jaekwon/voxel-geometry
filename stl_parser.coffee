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
    # TODO this could be more optimized, maybe.
    s = ''
    for i in [0...arrayBuffer.byteLength]
      s += String.fromCharCode(u8a[i])
    return parseAscii( s )
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

@parseAscii = parseAscii = ( text ) ->
  geometry = new THREE.Geometry()
  patternFace = /facet([\s\S]*?)endfacet/g
  result = undefined
  while (result = patternFace.exec( text )) != null
    facetext = result[ 0 ]
    # Normal
    patternNormal = /normal[\s]+([-+]?[0-9]+\.?[0-9]*([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+/g
    while (result = patternNormal.exec( facetext ) ) != null
      normal = new THREE.Vector3( Number(result[ 1 ]), Number(result[ 3 ]), Number(result[ 5 ]) )
    # Vertex
    patternVertex = /vertex[\s]+([-+]?[0-9]+\.?[0-9]*([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+/g
    while (result = patternVertex.exec( facetext ) ) != null
      geometry.vertices.push(  new THREE.Vector3( Number(result[ 1 ]), Number(result[ 3 ]), Number(result[ 5 ]) ) )
    len = geometry.vertices.length
    geometry.faces.push( new THREE.Face3( len - 3, len - 2, len - 1, normal ) )
  # Complete geometry data
  geometry.computeCentroids()
  geometry.computeBoundingSphere()
  geometry.computeFaceNormals()
  geometry.computeVertexNormals()
  return geometry
