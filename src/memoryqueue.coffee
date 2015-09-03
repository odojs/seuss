# Efficient memory based queue.
# Auto compacts if reduced by half
# Adapted from http://code.stephenmorley.org/javascript/queues/

Queue = (queue) ->
  queue = [] if !queue?
  offset = 0

  compact = ->
    queue = queue.slice offset
    offset = 0

  enqueue: (item) -> queue.push item

  dequeue: ->
    return undefined if queue.length is 0
    item = queue[offset]
    offset++
    # compact if half empty
    compact() if offset * 2 >= queue.length
    item

  peek: ->
    return undefined if queue.length is 0
    queue[offset]

  length: -> queue.length - offset
  all: ->
    compact()
    queue
  compact: compact

module.exports = Queue