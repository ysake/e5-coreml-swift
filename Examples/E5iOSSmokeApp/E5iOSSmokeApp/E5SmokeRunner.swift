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

    static func copyableReport(
        assetStatus: CoreMLTextEmbeddingAssetStatus?,
        deterministicReport: E5SmokeReport?,
        coreMLReport: E5SmokeReport?,
        validationReport: E5ValidationReport?,
        errorMessage: String?
    ) -> String {
        var lines: [String] = [
            "# E5 Smoke Validation Report",
            ""
        ]

        lines.append("## Bundled Assets")
        if let assetStatus {
            lines.append("- Ready: \(assetStatus.isReady ? "Yes" : "No")")
            if let modelURL = assetStatus.modelURL {
                lines.append("- Model: \(modelURL.lastPathComponent)")
            }
            if let modelSizeInBytes = assetStatus.modelSizeInBytes {
                let modelSize = ByteCountFormatter.string(
                    fromByteCount: modelSizeInBytes,
                    countStyle: .file
                )
                lines.append("- Model Size: \(modelSize)")
            }
            if let tokenizerDirectory = assetStatus.tokenizerDirectory {
                lines.append("- Tokenizer: \(tokenizerDirectory.lastPathComponent)")
            }
            if let errorDescription = assetStatus.errorDescription {
                lines.append("- Asset Error: \(errorDescription)")
            }
        } else {
            lines.append("- Ready: Not checked")
        }

        appendSmokeReport("Deterministic Smoke", deterministicReport, to: &lines)
        appendSmokeReport("Core ML Smoke", coreMLReport, to: &lines)

        lines.append("")
        lines.append("## Core ML Validation")
        if let validationReport {
            lines.append("- Related Similarity: \(validationReport.formattedRelatedSimilarity)")
            lines.append("- Unrelated Similarity: \(validationReport.formattedUnrelatedSimilarity)")
            lines.append("- Margin: \(validationReport.formattedSimilarityMargin)")
            lines.append("- Similarity Check: \(validationReport.passesSimilarityCheck ? "Pass" : "Fail")")
            lines.append("- Query Time: \(validationReport.query.formattedElapsedMilliseconds)")
            lines.append("- Related Time: \(validationReport.relatedPassage.formattedElapsedMilliseconds)")
            lines.append("- Unrelated Time: \(validationReport.unrelatedPassage.formattedElapsedMilliseconds)")
            appendEmbeddingChecks("Query", validationReport.query, to: &lines)
            appendEmbeddingChecks("Related", validationReport.relatedPassage, to: &lines)
            appendEmbeddingChecks("Unrelated", validationReport.unrelatedPassage, to: &lines)
            lines.append("- Query Text: \(validationReport.query.text)")
            lines.append("- Related Text: \(validationReport.relatedPassage.text)")
            lines.append("- Unrelated Text: \(validationReport.unrelatedPassage.text)")
        } else {
            lines.append("- Result: Not run")
        }

        if let errorMessage {
            lines.append("")
            lines.append("## Error")
            lines.append(errorMessage)
        }

        return lines.joined(separator: "\n")
    }

    private static func appendSmokeReport(
        _ title: String,
        _ report: E5SmokeReport?,
        to lines: inout [String]
    ) {
        lines.append("")
        lines.append("## \(title)")
        guard let report else {
            lines.append("- Result: Not run")
            return
        }

        lines.append("- Text: \(report.text)")
        lines.append("- Purpose: \(report.purpose.rawValue)")
        lines.append("- Dimension: \(report.dimension)")
        lines.append("- L2 Norm: \(report.formattedL2Norm)")
        lines.append("- Finite: \(report.isFinite ? "Yes" : "No")")
        lines.append("- All Zero: \(report.isAllZero ? "Yes" : "No")")
        lines.append("- Inference: \(report.formattedElapsedMilliseconds)")
        lines.append("- Preview: \(report.previewDescription)")
    }

    private static func appendEmbeddingChecks(
        _ title: String,
        _ report: E5SmokeReport,
        to lines: inout [String]
    ) {
        lines.append("- \(title) Dimension: \(report.dimension)")
        lines.append("- \(title) L2 Norm: \(report.formattedL2Norm)")
        lines.append("- \(title) Finite: \(report.isFinite ? "Yes" : "No")")
        lines.append("- \(title) All Zero: \(report.isAllZero ? "Yes" : "No")")
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
