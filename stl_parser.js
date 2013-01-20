// Generated by CoffeeScript 1.3.3

/*
@author aleeper / http://adamleeper.com/
@author mrdoob / http://mrdoob.com/
@author jaekwon / http://kopimism.org/

Description: A THREE loader for STL files, as created by Solidworks and other CAD programs.
Limitations: The binary loader could be optimized for memory.
*/


(function() {
  var Triangle, parseAscii, parseBinary;

  Triangle = function() {
    var _attr;
    this._sa = 0;
    this._buffer = new ArrayBuffer(50);
    this.__byte = new Uint8Array(this._buffer);
    this.normal = new Float32Array(this._buffer, this._sa + 0, 3);
    this.v1 = new Float32Array(this._buffer, this._sa + 12, 3);
    this.v2 = new Float32Array(this._buffer, this._sa + 24, 3);
    this.v3 = new Float32Array(this._buffer, this._sa + 36, 3);
    _attr = new Int16Array(this._buffer, this._sa + 48, 1);
    return Object.defineProperty(this, "attr", {
      get: function() {
        return _attr[0];
      },
      set: function(val) {
        return _attr[0] = val;
      },
      enumerable: true
    });
  };

  this.parse = function(data) {
    if (data.slice(0, 5) === 'solid') {
      return parseAscii(data);
    } else {
      return parseBinary(data);
    }
  };

  this.parseBinary = parseBinary = function(data) {
    var face, geometry, header, i, j, len, normal, numTriangles, offset, _i, _j;
    geometry = new THREE.Geometry();
    header = data.slice(0, 80);
    numTriangles = data.charCodeAt(80) << 0;
    numTriangles += data.charCodeAt(81) << 8;
    numTriangles += data.charCodeAt(82) << 16;
    numTriangles += data.charCodeAt(83) << 24;
    face = new Triangle();
    offset = 84;
    for (i = _i = 0; 0 <= numTriangles ? _i < numTriangles : _i > numTriangles; i = 0 <= numTriangles ? ++_i : --_i) {
      for (j = _j = 0; _j < 50; j = ++_j) {
        face.__byte[j] = data.charCodeAt(offset + j);
      }
      geometry.vertices.push(new THREE.Vector3(face.v1[0], face.v1[1], face.v1[2]));
      geometry.vertices.push(new THREE.Vector3(face.v2[0], face.v2[1], face.v2[2]));
      geometry.vertices.push(new THREE.Vector3(face.v3[0], face.v3[1], face.v3[2]));
      normal = new THREE.Vector3(face.normal[0], face.normal[1], face.normal[2]);
      len = geometry.vertices.length;
      geometry.faces.push(new THREE.Face3(len - 3, len - 2, len - 1, normal));
      offset += 50;
    }
    geometry.computeCentroids();
    geometry.computeBoundingSphere();
    return geometry;
  };

  this.parseAscii = parseAscii = function(data) {
    var geometry, len, normal, patternFace, patternNormal, patternVertex, result, text;
    geometry = new THREE.Geometry();
    patternFace = /facet([\s\S]*?)endfacet/g;
    result = void 0;
    while ((result = patternFace.exec(data)) !== null) {
      text = result[0];
      patternNormal = /normal[\s]+([-+]?[0-9]+\.?[0-9]*([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+/g;
      while ((result = patternNormal.exec(text)) !== null) {
        normal = new THREE.Vector3(result[1], result[3], result[5]);
      }
      patternVertex = /vertex[\s]+([-+]?[0-9]+\.?[0-9]*([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+/g;
      while ((result = patternVertex.exec(text)) !== null) {
        geometry.vertices.push(new THREE.Vector3(result[1], result[3], result[5]));
      }
      len = geometry.vertices.length;
      geometry.faces.push(new THREE.Face3(len - 3, len - 2, len - 1, normal));
    }
    geometry.computeCentroids();
    geometry.computeBoundingSphere();
    return geometry;
  };

}).call(this);
