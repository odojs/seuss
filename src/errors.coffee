util = require 'util'

SeussQueueBusy = ->
  @message = 'WARNING: Lock file found, is the queue in use?\nDelete if recovering from a crash.'
util.inherits SeussQueueBusy, Error

SeussQueueCorrupt = ->
  @message = 'WARNING: The queue file appears corrupt.\nFix or remove to continue.'
util.inherits SeussQueueBusy, Error

module.exports =
  SeussQueueBusy: SeussQueueBusy
  SeussQueueCorrupt: SeussQueueCorrupt