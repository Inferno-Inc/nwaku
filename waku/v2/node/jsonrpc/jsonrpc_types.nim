when (NimMajor, NimMinor) < (1, 4):
  {.push raises: [Defect].}
else:
  {.push raises: [].}

import
  std/[options,tables],
  eth/keys,
  ../../protocol/waku_message,
  ../../protocol/waku_store/rpc,
  ../../utils/time

type
  StoreResponse* = object
    messages*: seq[WakuMessage]
    pagingOptions*: Option[StorePagingOptions]

  StorePagingOptions* = object
    ## This type holds some options for pagination
    pageSize*: uint64
    cursor*: Option[PagingIndexRPC]
    forward*: bool

  WakuRelayMessage* = object
    payload*: seq[byte]
    contentTopic*: Option[ContentTopic]
    # sender generated timestamp
    timestamp*: Option[Timestamp]

  WakuPeer* = object
    multiaddr*: string
    protocol*: string
    connected*: bool

  WakuKeyPair* = object
    seckey*: keys.PrivateKey
    pubkey*: keys.PublicKey

  TopicCache* = TableRef[string, seq[WakuMessage]]

  MessageCache* = TableRef[ContentTopic, seq[WakuMessage]]
