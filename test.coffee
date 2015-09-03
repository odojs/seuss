seuss = require './'

queue = seuss.create './test.queue'
queue.enqueue 'f1.' + Math.random()
queue.enqueue 'f2.' + Math.random()
queue.dequeue()
queue.enqueue 'f3.' + Math.random()
queue.enqueue 'f4.' + Math.random()
queue.dequeue()
queue.enqueue 'f5.' + Math.random()
queue.enqueue 'f6.' + Math.random()
#queue.compact()
queue.close()

seuss.print './test.queue'