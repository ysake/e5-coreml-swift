import E5EmbeddingCore
@testable import E5iOSSmokeApp
import XCTest

final class E5iOSSmokeAppTests: XCTestCase {
    func testDeterministicSmokeRunsOnIOSSimulator() async throws {
        #if os(iOS)
        let report = try await E5SmokeRunner.deterministicSmoke(text: "検索テキスト")

        XCTAssertEqual(report.text, "検索テキスト")
        XCTAssertEqual(report.purpose, .query)
        XCTAssertEqual(report.dimension, 384)
        XCTAssertEqual(report.l2Norm, 1, accuracy: 0.0001)
        XCTAssertTrue(report.isFinite)
        XCTAssertFalse(report.isAllZero)
        XCTAssertGreaterThanOrEqual(report.elapsedMilliseconds, 0)
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
        XCTAssertNotNil(status.modelSizeInBytes)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }

    func testAppBundleCoreMLInferenceRunsOnIOSSimulator() async throws {
        #if os(iOS)
        let report = try await E5SmokeRunner.coreMLSmoke(text: "検索テキスト", bundle: .main)

        XCTAssertEqual(report.text, "検索テキスト")
        XCTAssertEqual(report.purpose, .query)
        XCTAssertEqual(report.dimension, 384)
        XCTAssertEqual(report.l2Norm, 1, accuracy: 0.01)
        XCTAssertTrue(report.isFinite)
        XCTAssertFalse(report.isAllZero)
        XCTAssertGreaterThanOrEqual(report.elapsedMilliseconds, 0)
        XCTAssertEqual(report.previewValues.count, 6)
        XCTAssertFalse(report.previewDescription.isEmpty)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }

    func testAppBundleCoreMLValidationComparesRelatedAndUnrelatedPassagesOnIOSSimulator() async throws {
        #if os(iOS)
        let report = try await E5SmokeRunner.coreMLValidation(
            queryText: "車内の収納を増やしたい",
            relatedPassageText: "セレナの荷室容量を増やすには、車内収納やルーフボックスを検討する。",
            unrelatedPassageText: "夕食にはトマトソースのパスタを作る。",
            bundle: .main
        )

        XCTAssertEqual(report.query.purpose, .query)
        XCTAssertEqual(report.relatedPassage.purpose, .passage)
        XCTAssertEqual(report.unrelatedPassage.purpose, .passage)
        XCTAssertTrue(report.query.isFinite)
        XCTAssertTrue(report.relatedPassage.isFinite)
        XCTAssertTrue(report.unrelatedPassage.isFinite)
        XCTAssertFalse(report.query.isAllZero)
        XCTAssertFalse(report.relatedPassage.isAllZero)
        XCTAssertFalse(report.unrelatedPassage.isAllZero)
        XCTAssertTrue(report.passesSimilarityCheck)
        XCTAssertGreaterThan(report.relatedSimilarity, report.unrelatedSimilarity)
        XCTAssertGreaterThan(report.similarityMargin, 0)
        #else
        throw XCTSkip("This validation test is intended for iOS Simulator.")
        #endif
    }
}
