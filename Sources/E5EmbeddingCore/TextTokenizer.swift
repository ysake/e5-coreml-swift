public protocol TextTokenizer: Sendable {
    func tokenize(_ text: String, purpose: EmbeddingPurpose) async throws -> TokenizedInput
}
