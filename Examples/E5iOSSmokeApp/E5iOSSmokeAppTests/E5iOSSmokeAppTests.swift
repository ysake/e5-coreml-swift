import E5EmbeddingCore
@testable import E5iOSSmokeApp
import XCTest

final class E5iOSSmokeAppTests: XCTestCase {
    func testDeterministicSmokeRunsOnIOSSimulator() async throws {
        #if os(iOS)
        let report = try await E5SmokeRunner.deterministicSmoke(text: "検索テキスト")

        XCTAssertEqual(report.text, "検索テキスト")
        XCTAssertEqual(report.dimension, 384)
        XCTAssertEqual(report.l2Norm, 1, accuracy: 0.0001)
        XCTAssertEqual(report.previewValues.count, 6)
        XCTAssertFalse(report.previewDescription.isEmpty)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }

    func testAppBundleAssetStatusReportsBundledAssetsOnIOSSimulator() {
        #if os(iOS)
        let status = E5SmokeRunner.assetStatus(bundle: .main)

        XCTAssertTrue(status.isReady, status.errorDescription ?? "E5 assets are not ready.")
        XCTAssertNotNil(status.modelURL)
        XCTAssertNotNil(status.tokenizerDirectory)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }

    func testAppBundleCoreMLInferenceRunsOnIOSSimulator() async throws {
        #if os(iOS)
        let report = try await E5SmokeRunner.coreMLSmoke(text: "検索テキスト", bundle: .main)

        XCTAssertEqual(report.text, "検索テキスト")
        XCTAssertEqual(report.dimension, 384)
        XCTAssertEqual(report.l2Norm, 1, accuracy: 0.01)
        XCTAssertEqual(report.previewValues.count, 6)
        XCTAssertFalse(report.previewDescription.isEmpty)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }
}
