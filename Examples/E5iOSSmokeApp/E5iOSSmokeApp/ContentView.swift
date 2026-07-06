import E5EmbeddingCore
import SwiftUI

struct ContentView: View {
    @State private var deterministicReport: E5SmokeReport?
    @State private var coreMLReport: E5SmokeReport?
    @State private var assetStatus: CoreMLTextEmbeddingAssetStatus?
    @State private var errorMessage: String?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            List {
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
                .disabled(isRunning)
            }
            .task {
                await runSmoke()
            }
        }
    }

    @MainActor
    private func runSmoke() async {
        isRunning = true
        errorMessage = nil
        assetStatus = E5SmokeRunner.assetStatus()
        defer { isRunning = false }

        do {
            deterministicReport = try await E5SmokeRunner.deterministicSmoke()
            coreMLReport = try await E5SmokeRunner.coreMLSmoke()
        } catch {
            deterministicReport = nil
            coreMLReport = nil
            errorMessage = error.localizedDescription
        }
    }
}

private struct SmokeReportView: View {
    let report: E5SmokeReport

    var body: some View {
        LabeledContent("Text", value: report.text)
        LabeledContent("Dimension", value: "\(report.dimension)")
        LabeledContent("L2 Norm", value: report.formattedL2Norm)
        Text(report.previewDescription)
            .font(.system(.footnote, design: .monospaced))
            .textSelection(.enabled)
    }
}

#Preview {
    ContentView()
}
