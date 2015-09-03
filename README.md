# Seuss
Resilient, persistent in process queues for Node.js.

Queues are backed by an append only binary file format for persistence. The binary format is compacted on restart or manually compacted by calling `queue.compact()`. An internal queue mirrors the file operations. The internal queue is also efficient and automatically compacts when reduced by half and is manually compacted as part of `queue.compact()`.

On disk persistence
- Crash resistant
- Atomic operations
- Preallocates blocks (defaults to 128k)
- Syncronous Node.js operations including fsync after every write

In memory queue
- Auto compacts after reducing by half

```js
var seuss = require('seuss');

// Open a queue
// Automatically compacts the queue
var queue = seuss.open('./test.queue');
// Look at the first element
// Returns undefined if not available
console.log(queue.peak());
// Strings are the only valid datatype (for now)
queue.enqueue('text');
queue.enqueue(JSON.stringify({ id: 1, message: 'text' }));
console.log(queue.dequeue());
console.log(queue.dequeue());
// Optional manual compact catt (queues shouldn't take up too much space)
// Best practice is to compact after x messages, or on a scheudule
queue.compact();
// Close is only needed on shutdown
queue.close();

// Print the contents of the queue, e.g. enqueues and dequeues
// Mostly for debugging
seuss.print('./test.queue');
// Will output something like:
// enqueue first
// enqueue second
// dequeue
// enqueue third
// enqueue fourth
// dequeue
// enqueue fifth
// enqueue sixth
// noop

// Read in a queue contents
var array = seuss.read('./test.queue');
console.log(array);
// Will output:
// ['third', 'fourth', 'fifth', 'sixth']

// Write out a new queue
var array = ['one', 'two', 'three'];
var queue = seuss.create('./test.queue');
array.forEach(queue.enqueue);
queue.close();
```
