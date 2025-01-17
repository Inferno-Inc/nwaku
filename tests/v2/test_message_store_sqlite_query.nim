{.used.}

import
  std/[options, sequtils, algorithm],
  unittest2,
  chronos
import
  ../../waku/common/sqlite,
  ../../waku/v2/node/message_store/sqlite_store,
  ../../waku/v2/protocol/waku_message,
  ../../waku/v2/protocol/waku_store,
  ./utils,
  ./testlib/common


proc newTestDatabase(): SqliteDatabase =
  SqliteDatabase.new(":memory:").tryGet()


suite "message store - history query":

  test "single content topic":
    ## Given
    const contentTopic = "test-content-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),

      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=ts(3)),

      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=ts(5)),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic, ts=ts(7)),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages[2..3]
    
    ## Teardown
    store.close()
  
  test "single content topic and descending order":
    ## Given
    const contentTopic = "test-content-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),

      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=ts(3)),
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=ts(5)),
      
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic, ts=ts(7)),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      maxPageSize=2,
      ascendingOrder=false
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages[6..7].reversed
    
    ## Teardown
    store.close()

  test "multiple content topic":
    ## Given
    const contentTopic1 = "test-content-topic-1"
    const contentTopic2 = "test-content-topic-2"
    const contentTopic3 = "test-content-topic-3"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),

      fakeWakuMessage("MSG-01", contentTopic=contentTopic1, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic2, ts=ts(3)),

      fakeWakuMessage("MSG-03", contentTopic=contentTopic3, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic1, ts=ts(5)),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic2, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic3, ts=ts(7)),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic1, contentTopic2]),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic in @[contentTopic1, contentTopic2]
      filteredMessages == messages[2..3]

    ## Teardown
    store.close()
  
  test "content topic and pubsub topic":
    ## Given
    const contentTopic = "test-content-topic"
    const pubsubTopic = "test-pubsub-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages1 = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),

      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=ts(3)),
    ]
    for msg in messages1:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
      

    let messages2 = @[
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=ts(5)),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic, ts=ts(7)),
    ]
    for msg in messages2:
      require store.put(pubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
     
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      pubsubTopic=some(pubsubTopic),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages2[0..1]

    ## Teardown
    store.close()

  test "content topic and cursor":
    ## Given
    const contentTopic = "test-content-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),

      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=ts(3)),

      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=ts(5)),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic, ts=ts(7)),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()

    let cursor = HistoryCursor(
      pubsubTopic: DefaultPubsubTopic,
      senderTime: messages[4].timestamp,
      storeTime: messages[4].timestamp,
      digest: computeDigest(messages[4])
    )
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      cursor=some(cursor),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages[5..6]

    ## Teardown
    store.close()

  test "content topic, cursor and descending order":
    ## Given
    const contentTopic = "test-content-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),

      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=ts(3)),
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=ts(5)),

      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic, ts=ts(7)),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()

    let cursor = HistoryCursor(
      pubsubTopic: DefaultPubsubTopic,
      senderTime: messages[6].timestamp,
      storeTime: messages[6].timestamp,
      digest: computeDigest(messages[6])
    )
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      cursor=some(cursor),
      maxPageSize=2,
      ascendingOrder=false
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages[4..5].reversed

    ## Teardown
    store.close()

  test "content topic, pubsub topic and cursor":
    ## Given
    const contentTopic = "test-content-topic"
    const pubsubTopic = "test-pubsub-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages1 = @[
      fakeWakuMessage(ts=ts(0)),
      fakeWakuMessage(ts=ts(1)),
      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=ts(3)),
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=ts(4)),
    ]
    for msg in messages1:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()

    let messages2 = @[
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=ts(5)),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=ts(6)),
      fakeWakuMessage("MSG-06", contentTopic=contentTopic, ts=ts(7)),
    ]
    for msg in messages2:
      require store.put(pubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()

    let cursor = HistoryCursor(
      pubsubTopic: DefaultPubsubTopic,
      senderTime: messages2[0].timestamp,
      storeTime: messages2[0].timestamp,
      digest: computeDigest(messages2[0])
    )
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      pubsubTopic=some(pubsubTopic),
      cursor=some(cursor),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages2[0..1]
    
    ## Teardown
    store.close()

  test "single content topic - no results":
    ## Given
    const contentTopic = "test-content-topic"

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage("MSG-01", contentTopic=DefaultContentTopic, ts=ts(2)),
      fakeWakuMessage("MSG-02", contentTopic=DefaultContentTopic, ts=ts(3)),
      fakeWakuMessage("MSG-03", contentTopic=DefaultContentTopic, ts=ts(4)),
      fakeWakuMessage("MSG-04", contentTopic=DefaultContentTopic, ts=ts(5)),
      fakeWakuMessage("MSG-05", contentTopic=DefaultContentTopic, ts=ts(6)),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 0
    
    ## Teardown
    store.close()

  test "content topic and page size":
    ## Given
    let pageSize: uint64 = 50
    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    for t in 0..<70:
      let msg = fakeWakuMessage("MSG-" & $t, DefaultContentTopic, ts=ts(t))
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[DefaultContentTopic]),
      maxPageSize=pageSize,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 50
    
    ## Teardown
    store.close()
  
  test "content topic and page size - not enough messages stored":
    ## Given
    let pageSize: uint64 = 50
    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    for t in 0..<40:
      let msg = fakeWakuMessage("MSG-" & $t, DefaultContentTopic, ts=ts(t))
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[DefaultContentTopic]),
      maxPageSize=pageSize,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 40
    
    ## Teardown
    store.close()
  
  test "single content topic and valid time range":
    ## Given
    const contentTopic = "test-content-topic"
    let timeOrigin = now()

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=timeOrigin + 00),
      
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=timeOrigin + 10),
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=timeOrigin + 20),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=timeOrigin + 30),

      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=timeOrigin + 50),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      startTime=some(timeOrigin + 5),
      endTime=some(timeOrigin + 35),
      maxPageSize=2,
      ascendingOrder=true
    )

    ## Then
    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 2
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages[1..2]

    ## Teardown
    store.close()
  
  test "single content topic and invalid time range - no results":
    ## Given
    const contentTopic = "test-content-topic"
    let timeOrigin = now()

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=timeOrigin + 00),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=timeOrigin + 10),
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=timeOrigin + 20),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=timeOrigin + 30),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=timeOrigin + 50),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      startTime=some(timeOrigin + 35),
      endTime=some(timeOrigin + 10),
      maxPageSize=2,
      ascendingOrder=true
    )

    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 0
    
    ## Teardown
    store.close()
  
  test "single content topic and only time range start":
    ## Given
    const contentTopic = "test-content-topic"
    let timeOrigin = now()

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=timeOrigin + 00),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=timeOrigin + 10),
      
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=timeOrigin + 20),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=timeOrigin + 30),
      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=timeOrigin + 50),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()
    
    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      startTime=some(timeOrigin + 15),
      ascendingOrder=false
    )

    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 3
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == messages[2..4].reversed
    
    ## Teardown
    store.close()
  
  test "single content topic, cursor and only time range start":
    ## Given
    const contentTopic = "test-content-topic"
    let timeOrigin = now()

    let 
      database = newTestDatabase()
      store = SqliteStore.init(database).tryGet()

    let messages = @[
      fakeWakuMessage("MSG-01", contentTopic=contentTopic, ts=timeOrigin + 00),
      fakeWakuMessage("MSG-02", contentTopic=contentTopic, ts=timeOrigin + 10),
      
      fakeWakuMessage("MSG-03", contentTopic=contentTopic, ts=timeOrigin + 20),
      fakeWakuMessage("MSG-04", contentTopic=contentTopic, ts=timeOrigin + 30),

      fakeWakuMessage("MSG-05", contentTopic=contentTopic, ts=timeOrigin + 50),
    ]

    for msg in messages:
      require store.put(DefaultPubsubTopic, msg, computeDigest(msg), msg.timestamp).isOk()

    let cursor = HistoryCursor(
      pubsubTopic: DefaultPubsubTopic,
      senderTime: messages[3].timestamp,
      storeTime: messages[3].timestamp,
      digest: computeDigest(messages[3])
    )

    ## When
    let res = store.getMessagesByHistoryQuery(
      contentTopic=some(@[contentTopic]),
      cursor=some(cursor),
      startTime=some(timeOrigin + 15),
      maxPageSize=2,
      ascendingOrder=true
    )

    check:
      res.isOk()

    let filteredMessages = res.tryGet().mapIt(it[1])
    check:
      filteredMessages.len == 1
      filteredMessages.all do (msg: WakuMessage) -> bool:
        msg.contentTopic == contentTopic
      filteredMessages == @[messages[^1]]

    ## Teardown
    store.close()
