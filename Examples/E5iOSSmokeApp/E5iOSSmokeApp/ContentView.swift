import E5EmbeddingCore
import Foundation
import SwiftUI

struct ContentView: View {
    @State private var deterministicReport: E5SmokeReport?
    @State private var coreMLReport: E5SmokeReport?
    @State private var validationReport: E5ValidationReport?
    @State private var assetStatus: CoreMLTextEmbeddingAssetStatus?
    @State private var errorMessage: String?
    @State private var isRunning = false
    @State private var queryText = E5SmokeRunner.sampleText
    @State private var relatedPassageText = E5SmokeRunner.sampleRelatedText
    @State private var unrelatedPassageText = E5SmokeRunner.sampleUnrelatedText

    private var canRunSmoke: Bool {
        !isRunning && [
            queryText,
            relatedPassageText,
            unrelatedPassageText
        ].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Input") {
                    TextField("Query", text: $queryText, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Related passage", text: $relatedPassageText, axis: .vertical)
                        .lineLimit(1...4)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Unrelated passage", text: $unrelatedPassageText, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Deterministic Smoke") {
                    if let deterministicReport {
                        SmokeReportView(report: deterministicReport)
                    } else {
                        Text(isRunning ? "Running..." : "Not run")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Bundled Assets") {
                    if let assetStatus {
                        LabeledContent("Ready", value: assetStatus.isReady ? "Yes" : "No")
                        if let modelURL = assetStatus.modelURL {
                            LabeledContent("Model", value: modelURL.lastPathComponent)
                        }
                        if let modelSizeInBytes = assetStatus.modelSizeInBytes {
                            LabeledContent("Model Size", value: ByteCountFormatter.string(
                                fromByteCount: modelSizeInBytes,
                                countStyle: .file
                            ))
                        }
                        if let tokenizerDirectory = assetStatus.tokenizerDirectory {
                            LabeledContent("Tokenizer", value: tokenizerDirectory.lastPathComponent)
                        }
                        if let errorDescription = assetStatus.errorDescription {
                            Text(errorDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("Not checked")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Core ML Smoke") {
                    if let coreMLReport {
                        SmokeReportView(report: coreMLReport)
                    } else {
                        Text(isRunning ? "Running..." : "Not run")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Core ML Validation") {
                    if let validationReport {
                        ValidationReportView(report: validationReport)
                    } else {
                        Text(isRunning ? "Running..." : "Not run")
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("E5 Smoke")
            .toolbar {
                Button(isRunning ? "Running" : "Run") {
                    Task {
                        await runSmoke()
                    }
                }
                .disabled(!canRunSmoke)
            }
            .onChange(of: queryText) { _, _ in resetReports() }
            .onChange(of: relatedPassageText) { _, _ in resetReports() }
            .onChange(of: unrelatedPassageText) { _, _ in resetReports() }
            .task {
                await runSmoke()
            }
        }
    }

    @MainActor
    private func runSmoke() async {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let relatedPassage = relatedPassageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let unrelatedPassage = unrelatedPassageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !relatedPassage.isEmpty, !unrelatedPassage.isEmpty else {
            resetReports()
            errorMessage = "Input texts must not be empty."
            return
        }

        isRunning = true
        errorMessage = nil
        assetStatus = E5SmokeRunner.assetStatus()
        defer { isRunning = false }

        do {
            deterministicReport = try await E5SmokeRunner.deterministicSmoke(text: query)
            coreMLReport = try await E5SmokeRunner.coreMLSmoke(text: query)
            validationReport = try await E5SmokeRunner.coreMLValidation(
                queryText: query,
                relatedPassageText: relatedPassage,
                unrelatedPassageText: unrelatedPassage
            )
        } catch {
            resetReports()
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func resetReports() {
        deterministicReport = nil
        coreMLReport = nil
        validationReport = nil
        errorMessage = nil
    }
}

private struct SmokeReportView: View {
    let report: E5SmokeReport

    var body: some View {
        LabeledContent("Text", value: report.text)
        LabeledContent("Purpose", value: report.purpose.rawValue)
        LabeledContent("Dimension", value: "\(report.dimension)")
        LabeledContent("L2 Norm", value: report.formattedL2Norm)
        LabeledContent("Finite", value: report.isFinite ? "Yes" : "No")
        LabeledContent("All Zero", value: report.isAllZero ? "Yes" : "No")
        LabeledContent("Inference", value: report.formattedElapsedMilliseconds)
        Text(report.previewDescription)
            .font(.system(.footnote, design: .monospaced))
            .textSelection(.enabled)
    }
}

private struct ValidationReportView: View {
    let report: E5ValidationReport

    var body: some View {
        LabeledContent("Related Similarity", value: report.formattedRelatedSimilarity)
        LabeledContent("Unrelated Similarity", value: report.formattedUnrelatedSimilarity)
        LabeledContent("Margin", value: report.formattedSimilarityMargin)
        LabeledContent("Similarity Check", value: report.passesSimilarityCheck ? "Pass" : "Fail")
        LabeledContent("Query Time", value: report.query.formattedElapsedMilliseconds)
        LabeledContent("Related Time", value: report.relatedPassage.formattedElapsedMilliseconds)
        LabeledContent("Unrelated Time", value: report.unrelatedPassage.formattedElapsedMilliseconds)
        ValidationEmbeddingChecks(title: "Query Checks", report: report.query)
        ValidationEmbeddingChecks(title: "Related Checks", report: report.relatedPassage)
        ValidationEmbeddingChecks(title: "Unrelated Checks", report: report.unrelatedPassage)
        Text("Query: \(report.query.text)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        Text("Related: \(report.relatedPassage.text)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        Text("Unrelated: \(report.unrelatedPassage.text)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}

private struct ValidationEmbeddingChecks: View {
    let title: String
    let report: E5SmokeReport

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
        LabeledContent("Dimension", value: "\(report.dimension)")
        LabeledContent("L2 Norm", value: report.formattedL2Norm)
        LabeledContent("Finite", value: report.isFinite ? "Yes" : "No")
        LabeledContent("All Zero", value: report.isAllZero ? "Yes" : "No")
    }
}

#Preview {
    ContentView()
}
