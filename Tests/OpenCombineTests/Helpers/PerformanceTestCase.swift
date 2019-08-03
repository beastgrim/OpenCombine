//
//  File.swift
//  
//
//  Created by Sergej Jaskiewicz on 13.06.2019.
//

import GottaGoFast
import XCTest

class PerformanceTestCase: GottaGoFast.PerformanceTestCase {
#if OPENCOMBINE_COMPATIBILITY_TEST
    override var testInfo: String {
        "OPENCOMBINE_COMPATIBILITY_TEST"
    }
#endif

    @discardableResult
    @inline(never)
    override func benchmark(file: StaticString = #file,
                            line: UInt = #line,
                            allowFailure: Bool = false,
                            executionCount: Int = 10,
                            strategy: BenchmarkStrategy = .minimum,
                            _ block: () throws -> Void) throws -> BenchmarkResult? {
        if isDebug {
            print("⚠️ Benchmarks will only be run in release configuration")
            return nil
        }

        return try super.benchmark(file: file,
                                   line: line,
                                   allowFailure: allowFailure,
                                   executionCount: executionCount,
                                   strategy: strategy,
                                   block)
    }

#if DEBUG
    var isDebug = true
#else
    var isDebug = false
#endif
}
