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

    func testCopyableReportIncludesValidationDetails() {
        let assetStatus = CoreMLTextEmbeddingAssetStatus(
            isReady: true,
            modelURL: URL(fileURLWithPath: "/tmp/E5SmallEmbedding.mlpackage"),
            tokenizerDirectory: URL(fileURLWithPath: "/tmp/Tokenizer"),
            modelSizeInBytes: 224_000_000,
            errorDescription: nil
        )
        let query = E5SmokeReport(
            text: "車内の収納を増やしたい",
            purpose: .query,
            dimension: 384,
            l2Norm: 1,
            isFinite: true,
            isAllZero: false,
            elapsedMilliseconds: 12.3,
            previewValues: [0.1, -0.2]
        )
        let related = E5SmokeReport(
            text: "車内収納を増やす。",
            purpose: .passage,
            dimension: 384,
            l2Norm: 1,
            isFinite: true,
            isAllZero: false,
            elapsedMilliseconds: 13.4,
            previewValues: [0.2, -0.1]
        )
        let unrelated = E5SmokeReport(
            text: "夕食にパスタを作る。",
            purpose: .passage,
            dimension: 384,
            l2Norm: 1,
            isFinite: true,
            isAllZero: false,
            elapsedMilliseconds: 14.5,
            previewValues: [-0.2, 0.1]
        )
        let validation = E5ValidationReport(
            query: query,
            relatedPassage: related,
            unrelatedPassage: unrelated,
            relatedSimilarity: 0.82,
            unrelatedSimilarity: 0.21
        )

        let report = E5SmokeRunner.copyableReport(
            assetStatus: assetStatus,
            deterministicReport: query,
            coreMLReport: query,
            validationReport: validation,
            errorMessage: nil
        )

        XCTAssertTrue(report.contains("# E5 Smoke Validation Report"))
        XCTAssertTrue(report.contains("- Ready: Yes"))
        XCTAssertTrue(report.contains("- Model: E5SmallEmbedding.mlpackage"))
        XCTAssertTrue(report.contains("- Dimension: 384"))
        XCTAssertTrue(report.contains("- L2 Norm: 1.0000"))
        XCTAssertTrue(report.contains("- Finite: Yes"))
        XCTAssertTrue(report.contains("- All Zero: No"))
        XCTAssertTrue(report.contains("- Related Similarity: 0.8200"))
        XCTAssertTrue(report.contains("- Unrelated Similarity: 0.2100"))
        XCTAssertTrue(report.contains("- Margin: 0.6100"))
        XCTAssertTrue(report.contains("- Similarity Check: Pass"))
        XCTAssertTrue(report.contains("- Query Text: 車内の収納を増やしたい"))
    }
}
