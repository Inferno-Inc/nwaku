import
  std/times,
  stew/byteutils
import
  ../../../waku/v2/protocol/waku_message,
  ../../../waku/v2/utils/time

export
  waku_message.DefaultPubsubTopic,
  waku_message.DefaultContentTopic


proc now*(): Timestamp =
  getNanosecondTime(getTime().toUnixFloat())

proc ts*(offset=0, origin=now()): Timestamp =
  origin + getNanosecondTime(offset)


proc fakeWakuMessage*(
  payload: string|seq[byte] = "TEST-PAYLOAD",
  contentTopic = DefaultContentTopic, 
  ts = now(),
  ephemeral = false
): WakuMessage = 
  var payloadBytes: seq[byte]
  when payload is string:
    payloadBytes = toBytes(payload)
  else:
    payloadBytes = payload

  WakuMessage(
    payload: payloadBytes,
    contentTopic: contentTopic,
    version: 2,
    timestamp: ts,
    ephemeral: ephemeral
  )
  