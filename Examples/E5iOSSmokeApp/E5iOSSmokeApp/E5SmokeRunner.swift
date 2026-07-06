import E5EmbeddingCore
import Foundation

struct E5SmokeReport: Equatable, Sendable {
    let text: String
    let purpose: EmbeddingPurpose
    let dimension: Int
    let l2Norm: Float
    let isFinite: Bool
    let isAllZero: Bool
    let elapsedMilliseconds: Double
    let previewValues: [Float]

    var formattedL2Norm: String {
        String(format: "%.4f", l2Norm)
    }

    var formattedElapsedMilliseconds: String {
        String(format: "%.1f ms", elapsedMilliseconds)
    }

    var previewDescription: String {
        let values = previewValues
            .map { String(format: "%.4f", $0) }
            .joined(separator: ", ")
        return "[\(values)]"
    }
}

struct E5ValidationReport: Equatable, Sendable {
    let query: E5SmokeReport
    let relatedPassage: E5SmokeReport
    let unrelatedPassage: E5SmokeReport
    let relatedSimilarity: Float
    let unrelatedSimilarity: Float

    var similarityMargin: Float {
        relatedSimilarity - unrelatedSimilarity
    }

    var passesSimilarityCheck: Bool {
        relatedSimilarity > unrelatedSimilarity
    }

    var formattedRelatedSimilarity: String {
        String(format: "%.4f", relatedSimilarity)
    }

    var formattedUnrelatedSimilarity: String {
        String(format: "%.4f", unrelatedSimilarity)
    }

    var formattedSimilarityMargin: String {
        String(format: "%.4f", similarityMargin)
    }
}

enum E5SmokeRunner {
    static let sampleText = "車内の収納を増やしたい"
    static let sampleRelatedText = "セレナの荷室容量を増やすには、車内収納やルーフボックスを検討する。"
    static let sampleUnrelatedText = "夕食にはトマトソースのパスタを作る。"

    static func assetStatus(bundle: Bundle = .main) -> CoreMLTextEmbeddingAssetStatus {
        CoreMLTextEmbeddingAssets.appBundle(bundle).status()
    }

    static func deterministicSmoke(
        text: String = sampleText,
        previewCount: Int = 6
    ) async throws -> E5SmokeReport {
        let embedder = DeterministicTextEmbedder()
        return try await smokeReport(
            embedder: embedder,
            text: text,
            purpose: .query,
            previewCount: previewCount
        )
    }

    static func coreMLSmoke(
        text: String = sampleText,
        previewCount: Int = 6,
        bundle: Bundle = .main
    ) async throws -> E5SmokeReport {
        let embedder = try CoreMLTextEmbedder(
            assets: CoreMLTextEmbeddingAssets.appBundle(bundle)
        )
        return try await smokeReport(
            embedder: embedder,
            text: text,
            purpose: .query,
            previewCount: previewCount
        )
    }

    static func coreMLValidation(
        queryText: String = sampleText,
        relatedPassageText: String = sampleRelatedText,
        unrelatedPassageText: String = sampleUnrelatedText,
        previewCount: Int = 6,
        bundle: Bundle = .main
    ) async throws -> E5ValidationReport {
        let embedder = try CoreMLTextEmbedder(
            assets: CoreMLTextEmbeddingAssets.appBundle(bundle)
        )

        let query = try await embeddingMeasurement(
            embedder: embedder,
            text: queryText,
            purpose: .query,
            previewCount: previewCount
        )
        let relatedPassage = try await embeddingMeasurement(
            embedder: embedder,
            text: relatedPassageText,
            purpose: .passage,
            previewCount: previewCount
        )
        let unrelatedPassage = try await embeddingMeasurement(
            embedder: embedder,
            text: unrelatedPassageText,
            purpose: .passage,
            previewCount: previewCount
        )

        return E5ValidationReport(
            query: query.report,
            relatedPassage: relatedPassage.report,
            unrelatedPassage: unrelatedPassage.report,
            relatedSimilarity: try CosineSimilarity.checkedDot(
                query.embedding,
                relatedPassage.embedding
            ),
            unrelatedSimilarity: try CosineSimilarity.checkedDot(
                query.embedding,
                unrelatedPassage.embedding
            )
        )
    }

    private static func smokeReport(
        embedder: TextEmbedder,
        text: String,
        purpose: EmbeddingPurpose,
        previewCount: Int
    ) async throws -> E5SmokeReport {
        try await embeddingMeasurement(
            embedder: embedder,
            text: text,
            purpose: purpose,
            previewCount: previewCount
        ).report
    }

    private static func embeddingMeasurement(
        embedder: TextEmbedder,
        text: String,
        purpose: EmbeddingPurpose,
        previewCount: Int
    ) async throws -> E5EmbeddingMeasurement {
        let startDate = Date()
        let embedding = try await embedder.embed(text, purpose: purpose)
        let elapsedMilliseconds = Date().timeIntervalSince(startDate) * 1_000

        return E5SmokeReport(
            text: text,
            purpose: purpose,
            dimension: embedding.count,
            l2Norm: CosineSimilarity.l2Norm(embedding),
            isFinite: embedding.allSatisfy { $0.isFinite },
            isAllZero: embedding.allSatisfy { $0 == 0 },
            elapsedMilliseconds: elapsedMilliseconds,
            previewValues: Array(embedding.prefix(previewCount))
        )
        .measurement(embedding: embedding)
    }
}

private struct E5EmbeddingMeasurement: Sendable {
    let report: E5SmokeReport
    let embedding: [Float]
}

private extension E5SmokeReport {
    func measurement(embedding: [Float]) -> E5EmbeddingMeasurement {
        E5EmbeddingMeasurement(report: self, embedding: embedding)
    }
}
