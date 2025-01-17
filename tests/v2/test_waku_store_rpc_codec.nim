{.used.}

import
  std/[options, times],
  testutils/unittests,
  chronos
import
  ../../waku/v2/protocol/waku_store/rpc,
  ../../waku/v2/protocol/waku_store/rpc_codec,
  ../../waku/v2/utils/time,
  ./testlib/common


procSuite "Waku Store - RPC codec":
  
  test "PagingIndexRPC protobuf codec":
    ## Given
    let index = PagingIndexRPC.compute(fakeWakuMessage(), receivedTime=ts(), pubsubTopic=DefaultPubsubTopic)

    ## When
    let encodedIndex = index.encode()
    let decodedIndexRes = PagingIndexRPC.decode(encodedIndex.buffer)

    ## Then
    check:
      decodedIndexRes.isOk()
    
    let decodedIndex = decodedIndexRes.tryGet()
    check:
      # The fields of decodedIndex must be the same as the original index
      decodedIndex == index

  test "PagingIndexRPC protobuf codec - empty index":
    ## Given
    let emptyIndex = PagingIndexRPC()
    
    let encodedIndex = emptyIndex.encode()
    let decodedIndexRes = PagingIndexRPC.decode(encodedIndex.buffer)

    ## Then
    check:
      decodedIndexRes.isOk()
    
    let decodedIndex = decodedIndexRes.tryGet()
    check:
      # Check the correctness of init and encode for an empty PagingIndexRPC
      decodedIndex == emptyIndex

  test "PagingInfoRPC protobuf codec":
    ## Given
    let
      index = PagingIndexRPC.compute(fakeWakuMessage(), receivedTime=ts(), pubsubTopic=DefaultPubsubTopic)
      pagingInfo = PagingInfoRPC(pageSize: 1, cursor: index, direction: PagingDirectionRPC.FORWARD)
      
    ## When
    let pb = pagingInfo.encode()
    let decodedPagingInfo = PagingInfoRPC.decode(pb.buffer)

    ## Then
    check:
      decodedPagingInfo.isOk()

    check:
      # the fields of decodedPagingInfo must be the same as the original pagingInfo
      decodedPagingInfo.value == pagingInfo
      decodedPagingInfo.value.direction == pagingInfo.direction
  
  test "PagingInfoRPC protobuf codec - empty paging info":
    ## Given
    let emptyPagingInfo = PagingInfoRPC()
      
    ## When
    let pb = emptyPagingInfo.encode()
    let decodedEmptyPagingInfo = PagingInfoRPC.decode(pb.buffer)

    ## Then
    check:
      decodedEmptyPagingInfo.isOk()

    check:
      # check the correctness of init and encode for an empty PagingInfoRPC
      decodedEmptyPagingInfo.value == emptyPagingInfo
  
  test "HistoryQueryRPC protobuf codec":
    ## Given
    let
      index = PagingIndexRPC.compute(fakeWakuMessage(), receivedTime=ts(), pubsubTopic=DefaultPubsubTopic)
      pagingInfo = PagingInfoRPC(pageSize: 1, cursor: index, direction: PagingDirectionRPC.BACKWARD)
      query = HistoryQueryRPC(contentFilters: @[HistoryContentFilterRPC(contentTopic: DefaultContentTopic), HistoryContentFilterRPC(contentTopic: DefaultContentTopic)], pagingInfo: pagingInfo, startTime: Timestamp(10), endTime: Timestamp(11))
    
    ## When
    let pb = query.encode()
    let decodedQuery = HistoryQueryRPC.decode(pb.buffer)

    ## Then
    check:
      decodedQuery.isOk()

    check:
      # the fields of decoded query decodedQuery must be the same as the original query query
      decodedQuery.value == query

  test "HistoryQueryRPC protobuf codec - empty history query":
    ## Given
    let emptyQuery = HistoryQueryRPC()

    ## When
    let pb = emptyQuery.encode()
    let decodedEmptyQuery = HistoryQueryRPC.decode(pb.buffer)

    ## Then
    check:
      decodedEmptyQuery.isOk()

    check:
      # check the correctness of init and encode for an empty HistoryQueryRPC
      decodedEmptyQuery.value == emptyQuery
  
  test "HistoryResponseRPC protobuf codec":
    ## Given
    let
      message = fakeWakuMessage()
      index = PagingIndexRPC.compute(message, receivedTime=ts(), pubsubTopic=DefaultPubsubTopic)
      pagingInfo = PagingInfoRPC(pageSize: 1, cursor: index, direction: PagingDirectionRPC.BACKWARD)
      res = HistoryResponseRPC(messages: @[message], pagingInfo:pagingInfo, error: HistoryResponseErrorRPC.INVALID_CURSOR)
    
    ## When
    let pb = res.encode()
    let decodedRes = HistoryResponseRPC.decode(pb.buffer)

    ## Then
    check:
      decodedRes.isOk()

    check:
      # the fields of decoded response decodedRes must be the same as the original response res
      decodedRes.value == res
    
  test "HistoryResponseRPC protobuf codec - empty history response":
    ## Given
    let emptyRes = HistoryResponseRPC()
    
    ## When
    let pb = emptyRes.encode()
    let decodedEmptyRes = HistoryResponseRPC.decode(pb.buffer)

    ## Then
    check:
      decodedEmptyRes.isOk()

    check:
      # check the correctness of init and encode for an empty HistoryResponseRPC
      decodedEmptyRes.value == emptyRes