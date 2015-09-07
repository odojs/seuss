usage = """
Usage: seuss command [parameter] file

View:
  cat                     Print entire queue contents
  peek n..m               Print rows n..m inclusive

Manipulate:
  rm n..m                 Remove and print rows n..m inclusive
  insert index message    Insert a message into the queue
  enqueue message         Add message to the queue
  dequeue                 Remove and print a message from the queue
  purge                   Remove all messages from the queue

Options:
  -h                      Display this usage information
  -v                      Display the version number

"""

process.on 'uncaughtException', (err) ->
  console.error 'Caught exception: '
  console.error err.stack
  process.exit 1

# General purpose printing an error and usage
usage_error = (message) =>
  console.error()
  console.error "  #{message}"
  console.error()
  console.error usage
  process.exit 1

args = process.argv[2..]

return console.error usage if args.length is 0

seuss = require '../'
{ SeussQueueBusy } = require '../src/errors'

commands =
  peek: (r, path) ->
    messages = seuss.read path
    if messages.length is 0
      return console.error 'No messages in queue'
    clip_range r, messages
    for index in [r.start..r.end]
      message = messages[index - 1]
      console.log "#{index}) #{message}"

  rm: (r, path) ->
    messages = seuss.read path
    if messages.length is 0
      return console.error 'No messages in queue'
    clip_range r, messages
    if r.start > r.end
      r =
        start: r.end
        end: r.start
    removed = messages.splice r.start - 1, r.end - r.start + 1
    queue = seuss.create path
    for message in messages
      queue.enqueue message
    queue.close()
    for message, index in removed
      console.log "#{index + r.start}) #{message}"

  enqueue: (message, path) ->
    queue = seuss.open path
    queue.enqueue message
    queue.close()

  dequeue: (path) ->
    queue = seuss.open path
    console.log queue.dequeue()
    queue.compact()
    queue.close()

  cat: (path) ->
    messages = seuss.read path
    for message, index in messages
      console.log "#{index + 1}) #{message}"

  purge: (path) ->
    queue = seuss.create path
    queue.close()

  insert: (index, message, path) ->
    messages = seuss.read path
    index = Math.max index, 1
    index = Math.min index, messages.length + 1
    messages.splice index - 1, 0, message
    queue = seuss.create path
    for message in messages
      queue.enqueue message
    queue.close()
    console.log "#{index}) #{message}"

clip_range = (r, messages) ->
  r.start = 1 if r.start is ''
  r.end = messages.length if r.end is ''
  r.start = Math.min r.start, messages.length
  r.start = Math.max r.start, 1
  r.end = Math.min r.end, messages.length
  r.end = Math.max r.end, 1

parse_range = (s) ->
  if !s?
    return {
      start: 1
      end: 1
    }
  chunks = s.split '..'
  if chunks.length is 1
    start: s
    end: s
  else if chunks.length is 2
    start: chunks[0]
    end: chunks[1]
  else
    null

cmds =
  peek: ->
    if args.length is 1
      r = parse_range()
      path = args[0]
    else if args.length is 2
      r = parse_range args[0]
      path = args[1]

    if !path?
      usage_error 'seuss peek requires two arguments - the message index or range to print and the queue path'
    commands.peek r, path

  rm: ->
    if args.length is 1
      r = parse_range()
      path = args[0]
    else if args.length is 2
      r = parse_range args[0]
      path = args[1]

    if !path?
      usage_error 'seuss rm requires two arguments - the message index or range to remove and the queue path'
    commands.rm r, path

  insert: ->
    return commands.insert args[0], args[1], args[2] if args.length is 3
    usage_error 'seuss insert requires three arguments - the index to insert, the message to insert and the queue path'

  enqueue: ->
    return commands.enqueue args[0], args[1] if args.length is 2
    usage_error 'seuss enqueue requires two arguments - the message to enqueue and q the queue path'

  dequeue: ->
    return commands.dequeue args[0] if args.length is 1
    usage_error 'seuss dequeue requires one argument - the queue path'

  cat: ->
    return commands.cat args[0] if args.length is 1
    usage_error 'seuss cat requires one argument - the queue path'

  purge: ->
    return commands.purge args[0] if args.length is 1
    usage_error 'seuss purge requires one argument - the queue path'

  '-h': ->
    console.log usage

  '-v': ->
    pjson = require '../package.json'
    console.log pjson.version

command = args[0]
args.shift()
try
  return cmds[command]() if cmds[command]?
catch e
  if e instanceof SeussQueueBusy
    console.error e.message
    console.error()
  else
    console.error 'Caught exception: '
    console.error err.stack
  process.exit 1
usage_error "#{command} is not a known seuss command"