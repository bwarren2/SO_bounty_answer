# Collecting an SO bounty

Specifically, [this one](http://stackoverflow.com/questions/40140187/strange-docker-celery-bug).

## Build
`docker build --rm -t myapp .`

## Run Celery Worker

 * `docker run -it  -e REDISTOGO_URL=redis://:$PASS@$IP -e C_FORCE_ROOT=True myapp /bin/bash`
 * `cd app`
 * `celery worker -A tasks.celery -l debug`

## Make some tasks in a new tab

 * `docker ps` (get running instance id)
 * `docker exec -it $ID /bin/bash`
 * `cd app`
 * `python`

`import tasks`

`tasks.multiply.delay(3,5)`

($TASK-ID is {uuid} in \<AsyncResult: {uuid}\>)

## Check in on redis

 * `redis-cli -h IP -a PASS`
 * `keys *`
 * `get {$TASK_ID} // The one that has your task ID in it`

Some goofy string like:

    IP:PORT> get celery-task-meta-6b4e5e9c-df28-47f9-9f69-8ae265860e43
    "\x80\x02}q\x00(X\b\x00\x00\x00childrenq\x01]q\x02X\x06\x00\x00\x00resultq\x03K\x0fX\t\x00\x00\x00tracebackq\x04NX\x06\x00\x00\x00statusq\x05X\a\x00\x00\x00SUCCESSq\x06u."

## See the redis cleartext

    import pickle
    strng = "$YOUR RESULT"
    pickle.loads(strng)

    // >>> import pickle
    // >>> pickle.loads('\x80\x02}q\x00(X\b\x00\x00\x00childrenq\x01]q\x02X\x06\x00\x00\x00resultq\x03K\x0fX\t\x00\x00\x00tracebackq\x04NX\x06\x00\x00\x00statusq\x05X\a\x00\x00\x00SUCCESSq\x06u.')
    // {u'status': u'SUCCESS', u'traceback': None, u'children': [], u'result': 15}

## Meanwhile, in your worker:

    [2016-10-25 02:25:27,795: DEBUG/MainProcess] | Worker: Hub.register Pool...
    [2016-10-25 02:25:27,796: DEBUG/MainProcess] basic.qos: prefetch_count->16
    [2016-10-25 02:25:38,410: INFO/MainProcess] Received task: tasks.multiply[6b4e5e9c-df28-47f9-9f69-8ae265860e43]
    [2016-10-25 02:25:38,410: DEBUG/MainProcess] TaskPool: Apply <function _fast_trace_task at 0x7fe81def3d08> (args:('tasks.multiply', '6b4e5e9c-df28-47f9-9f69-8ae265860e43', (3, 5), {}, {'hostname': 'celery@f0614b4e5771', 'group': None, 'expires': None, 'errbacks': None, 'args': (3, 5), 'id': '6b4e5e9c-df28-47f9-9f69-8ae265860e43', 'kwargs': {}, 'reply_to': '8f38b31b-ddc8-3b59-a6dd-4789da831988', 'timelimit': (None, None), 'eta': None, 'is_eager': False, 'retries': 0, 'task': 'tasks.multiply', 'chord': None, 'headers': {}, 'delivery_info': {'priority': 0, 'redelivered': None, 'routing_key': 'celery', 'exchange': 'celery'}, 'callbacks': None, 'taskset': None, 'correlation_id': '6b4e5e9c-df28-47f9-9f69-8ae265860e43', 'utc': True}) kwargs:{})
    [2016-10-25 02:25:38,458: DEBUG/MainProcess] Task accepted: tasks.multiply[6b4e5e9c-df28-47f9-9f69-8ae265860e43] pid:32
    [2016-10-25 02:25:38,562: INFO/MainProcess] Task tasks.multiply[6b4e5e9c-df28-47f9-9f69-8ae265860e43] succeeded in 0.15006913599791005s: 15


## NOTE!

The C_FORCE_ROOT flag bypasses a security feature; running celery as root is usually bad, especially when you are using pickle for your serialization (as is the default).  This implementation still needs to be secured; I am spiking something that works.

## Changes made
 * Fixing the colon typo
 * Cleaning up tasks.py
 * Using a single redis URI, rather than 3 piece and formatting.
 * Not calling the decorators
 * Some directory navigation.
