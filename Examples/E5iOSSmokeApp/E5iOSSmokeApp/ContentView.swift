import E5EmbeddingCore
import SwiftUI

struct ContentView: View {
    @State private var report: E5SmokeReport?
    @State private var assetStatus: CoreMLTextEmbeddingAssetStatus?
    @State private var errorMessage: String?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            List {
                Section("Deterministic Smoke") {
                    if let report {
                        LabeledContent("Text", value: report.text)
                        LabeledContent("Dimension", value: "\(report.dimension)")
                        LabeledContent("L2 Norm", value: report.formattedL2Norm)
                        Text(report.previewDescription)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
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
            report = try await E5SmokeRunner.deterministicSmoke()
        } catch {
            report = nil
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
