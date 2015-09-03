fs = require 'graceful-fs'
markers = require './markers'
roundbyte = require './roundbyte'

module.exports = (path) ->
  buffer = fs.readFileSync path
  offset = 0
  while offset < buffer.length
    marker = buffer.readUInt32BE offset
    offset += 4
    break if marker is markers.noop
    if marker is markers.enqueue
      length = buffer.readUInt32BE offset
      offset += 4
      message = buffer.toString 'utf8', offset, offset + length
      offset += length
      offset = roundbyte offset
      console.log "enqueue #{message}"
    else if marker is markers.dequeue
      console.log 'dequeue'
    else
      throw 'Corrupt queue file - fix or remove'
  console.log 'noop'