# A file backed queue.

# Incremental backoff on EMFILE
fs = require 'graceful-fs'
Queue = require './memoryqueue'
markers = require './markers'
roundbyte = require './roundbyte'

# default buffer size 128k
DEFAULT_BUFFER_SIZE = 1024 * 128

seuss =
  create: (path, buffersize) ->
    # default buffer size
    buffersize = DEFAULT_BUFFER_SIZE if !buffersize?
    noopbuffer = new Buffer buffersize
    noopbuffer.fill markers.noop
    fd = fs.openSync path, 'w'
    fs.writeSync fd, noopbuffer, 0, buffersize, 0
    fs.fsyncSync fd
    offset = 0
    allocated = buffersize
    memqueue = Queue()
    fsqueue =
      enqueue: (message) ->
        length = Buffer.byteLength message
        size = roundbyte length + 8
        allocatesize = size
        if offset + size > allocated
          allocated = Math.ceil((offset + size) / buffersize) * buffersize
          allocatesize = allocated - offset
        buffer = new Buffer allocatesize
        buffer.writeUInt32BE markers.enqueue, 0
        buffer.writeUInt32BE length, 4
        buffer.write message, 8, length
        if length + 8 < allocatesize
          buffer.fill markers.noop, length + 8
        fs.writeSync fd, buffer, 0, allocatesize, offset
        fs.fsyncSync fd
        offset += size
      dequeue: ->
        buffer = new Buffer 4
        buffer.writeUInt32BE markers.dequeue
        if offset + 4 > allocated
          buffer = Buffer.concat [buffer, noopbuffer], buffersize + 4
          allocated += buffersize
        fs.writeSync fd, buffer, 0, buffer.length, offset
        fs.fsyncSync fd
        offset += 4
      compact: ->
        fd = fs.openSync "#{path}.new", 'w'
        fs.writeSync fd, noopbuffer, 0, buffersize, 0
        fs.fsyncSync fd
        offset = 0
        allocated = buffersize
        for message in memqueue.all()
          fsqueue.enqueue message
        fs.renameSync "#{path}.new", path
      close: ->
        fs.closeSync fd

    enqueue: (message) ->
      fsqueue.enqueue message
      memqueue.enqueue message
    dequeue: ->
      fsqueue.dequeue()
      memqueue.dequeue()
    peek: ->
      memqueue.peek()
    length: ->
      memqueue.length()
    all: ->
      memqueue.all()
    compact: ->
      fsqueue.compact()
      memqueue.compact()
    close: ->
      fsqueue.close()

  open: (path) ->
    queue = seuss.create "#{path}.new"
    if fs.existsSync path
      messages = seuss.read path
      for message in messages
        queue.enqueue message
    fs.renameSync "#{path}.new", path
    queue

  print: require './print'
  read: require './read'

module.exports = seuss