import Foundation
import Tokenizers

public struct HuggingFaceTextTokenizer: TextTokenizer {
    private let tokenizer: any Tokenizer
    private let inputBuilder: CoreMLInputBuilder

    public static func load(
        from tokenizerDirectory: URL,
        maxSequenceLength: Int = 128
    ) async throws -> HuggingFaceTextTokenizer {
        let tokenizer = try await AutoTokenizer.from(modelFolder: tokenizerDirectory)
        let inputBuilder = try CoreMLInputBuilder(maxSequenceLength: maxSequenceLength)
        return HuggingFaceTextTokenizer(tokenizer: tokenizer, inputBuilder: inputBuilder)
    }

    public init(tokenizer: any Tokenizer, inputBuilder: CoreMLInputBuilder) {
        self.tokenizer = tokenizer
        self.inputBuilder = inputBuilder
    }

    public func tokenize(_ text: String, purpose: EmbeddingPurpose) async throws -> TokenizedInput {
        guard !text.isEmpty else {
            throw EmbeddingError.emptyInput
        }

        let prefixedText = purpose.applyPrefix(to: text)
        let encodedTokenIDs = tokenizer.encode(text: prefixedText)
        let tokenIDs = try TokenIDConverter.int32TokenIDs(from: encodedTokenIDs)
        let coreMLInput = inputBuilder.buildInputIDs(from: tokenIDs)

        return TokenizedInput(
            prefixedText: prefixedText,
            tokenIDs: tokenIDs,
            coreMLInput: coreMLInput
        )
    }
}
