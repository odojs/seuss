fs = require 'graceful-fs'
markers = require './markers'
roundbyte = require './roundbyte'
{ SeussQueueCorrupt } = require './errors'

module.exports = (path) ->
  dequeues = 0
  result = []
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
      result.push message
    else if marker is markers.dequeue
      dequeues++
    else
      throw new SeussQueueCorrupt()
  reverse = []
  for i in [0...result.length]
    reverse.push result.pop()
  for i in [0...dequeues]
    reverse.pop()
  for i in [0...reverse.length]
    result.push reverse.pop()
  result