import E5EmbeddingCore
@testable import E5iOSSmokeApp
import XCTest

final class E5iOSSmokeAppTests: XCTestCase {
    func testDeterministicSmokeRunsOnIOSSimulator() async throws {
        #if os(iOS)
        let report = try await E5SmokeRunner.deterministicSmoke(text: "テスト")

        XCTAssertEqual(report.text, "テスト")
        XCTAssertEqual(report.dimension, 384)
        XCTAssertEqual(report.l2Norm, 1, accuracy: 0.0001)
        XCTAssertEqual(report.previewValues.count, 6)
        XCTAssertFalse(report.previewDescription.isEmpty)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }

    func testAppBundleAssetStatusCanBeEvaluatedOnIOSSimulator() {
        #if os(iOS)
        let status = E5SmokeRunner.assetStatus(bundle: .main)

        if status.isReady {
            XCTAssertNotNil(status.modelURL)
            XCTAssertNotNil(status.tokenizerDirectory)
        } else {
            XCTAssertNotNil(status.errorDescription)
        }
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }

    func testAppBundleCoreMLInferenceWhenAssetsAreBundled() async throws {
        #if os(iOS)
        let assets = CoreMLTextEmbeddingAssets.appBundle(.main)
        let status = assets.status()
        guard status.isReady else {
            throw XCTSkip("Core ML model/tokenizer assets are not bundled: \(status.errorDescription ?? "missing assets")")
        }

        let embedder = try CoreMLTextEmbedder(assets: assets)
        let embedding = try await embedder.embed("テスト", purpose: .query)

        XCTAssertEqual(embedding.count, 384)
        XCTAssertFalse(embedding.contains { $0.isNaN || !$0.isFinite })
        XCTAssertEqual(CosineSimilarity.l2Norm(embedding), 1, accuracy: 0.01)
        #else
        throw XCTSkip("This smoke test is intended for iOS Simulator.")
        #endif
    }
}
