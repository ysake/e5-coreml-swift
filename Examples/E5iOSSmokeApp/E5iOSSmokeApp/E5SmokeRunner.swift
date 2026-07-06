import E5EmbeddingCore
import Foundation

struct E5SmokeReport: Equatable, Sendable {
    let text: String
    let dimension: Int
    let l2Norm: Float
    let previewValues: [Float]

    var formattedL2Norm: String {
        String(format: "%.4f", l2Norm)
    }

    var previewDescription: String {
        let values = previewValues
            .map { String(format: "%.4f", $0) }
            .joined(separator: ", ")
        return "[\(values)]"
    }
}

enum E5SmokeRunner {
    static let sampleText = "テスト"

    static func assetStatus(bundle: Bundle = .main) -> CoreMLTextEmbeddingAssetStatus {
        CoreMLTextEmbeddingAssets.appBundle(bundle).status()
    }

    static func deterministicSmoke(
        text: String = sampleText,
        previewCount: Int = 6
    ) async throws -> E5SmokeReport {
        let embedder = DeterministicTextEmbedder()
        let embedding = try await embedder.embed(text, purpose: .query)
        return E5SmokeReport(
            text: text,
            dimension: embedding.count,
            l2Norm: CosineSimilarity.l2Norm(embedding),
            previewValues: Array(embedding.prefix(previewCount))
        )
    }
}
