//
//  DispatchQueueSchedulerTests.swift
//  
//
//  Created by Sergej Jaskiewicz on 26.08.2019.
//

import XCTest
import Dispatch

#if OPENCOMBINE_COMPATIBILITY_TEST
import Combine
#else
import OpenCombine
import OpenCombineDispatch
#endif

@available(macOS 10.15, iOS 13.0, *)
final class DispatchQueueSchedulerTests: XCTestCase {

    static let allTests = [
        ("testSchedulerTimeTypeDistance", testSchedulerTimeTypeDistance),
        ("testSchedulerTimeTypeAdvanced", testSchedulerTimeTypeAdvanced),
        ("testSchedulerTimeTypeEquatable", testSchedulerTimeTypeEquatable),
        ("testSchedulerTimeTypeHashable", testSchedulerTimeTypeHashable),
        ("testSchedulerTimeTypeCodable", testSchedulerTimeTypeCodable),
        ("testMinimumTolerance", testMinimumTolerance),
        ("testNow", testNow),
    ]

    func testSchedulerTimeTypeDistance() {
        let time1 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10000))
        let time2 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10431))

        XCTAssertEqual(time1.distance(to: time2), .nanoseconds(431))

        // A bug in Combine (FB7127210), caused by overflow on subtraction.
        // It should not crash. When they fix it, this test will fail and we'll know
        // that we need to update our implementation.
        assertCrashes {
            _ = time2.distance(to: time1)
        }
    }

    func testSchedulerTimeTypeAdvanced() {
        let time = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10000))
        let stride1 = Scheduler.SchedulerTimeType.Stride.nanoseconds(431)
        let stride2 = Scheduler.SchedulerTimeType.Stride.nanoseconds(-220)

        XCTAssertEqual(time.advanced(by: stride1),
                       Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10431)))

        XCTAssertEqual(time.advanced(by: stride2),
                       Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 9780)))
    }

    func testSchedulerTimeTypeEquatable() {
        let time1 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10000))
        let time2 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10000))
        let time3 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10001))

        XCTAssertEqual(time1, time1)
        XCTAssertEqual(time2, time2)
        XCTAssertEqual(time3, time3)

        XCTAssertEqual(time1, time2)
        XCTAssertEqual(time2, time1)
        XCTAssertNotEqual(time1, time3)
        XCTAssertNotEqual(time3, time1)
    }

    func testSchedulerTimeTypeHashable() {
        let time1 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10000))
        let time2 = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 10001))

        XCTAssertEqual(time1.hashValue, time1.dispatchTime.rawValue.hashValue)
        XCTAssertEqual(time2.hashValue, time2.dispatchTime.rawValue.hashValue)
    }

    func testSchedulerTimeTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let time = Scheduler.SchedulerTimeType(.init(uptimeNanoseconds: 42))
        let encodedData = try encoder
            .encode(KeyedWrapper(value: time))
        let encodedString = String(decoding: encodedData, as: UTF8.self)

        XCTAssertEqual(encodedString, #"{"value":42}"#)

        let decodedTime = try decoder
            .decode(KeyedWrapper<Scheduler.SchedulerTimeType>.self, from: encodedData)
            .value

        XCTAssertEqual(decodedTime, time)
    }

    func testMinimumTolerance() {
        XCTAssertEqual(mainScheduler.minimumTolerance, .nanoseconds(0))
    }

    func testNow() {
        let expectedNow = DispatchTime.now().uptimeNanoseconds
        let actualNow = mainScheduler.now.dispatchTime.uptimeNanoseconds
        XCTAssertLessThan(abs(actualNow.distance(to: expectedNow)),
                          100_000/*nanoseconds*/)
    }
}


#if OPENCOMBINE_COMPATIBILITY_TEST || !canImport(Combine)
@available(macOS 10.15, iOS 13.0, *)
private typealias Scheduler = DispatchQueue
private let mainScheduler = DispatchQueue.main
#else
private typealias Scheduler = DispatchQueue.OCombine
private let mainScheduler = DispatchQueue.main.ocombine
#endif

private struct KeyedWrapper<Value: Codable & Equatable>: Codable, Equatable {
    let value: Value
}
