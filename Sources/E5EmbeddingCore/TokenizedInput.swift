public struct TokenizedInput: Equatable, Sendable {
    public let prefixedText: String
    public let tokenIDs: [Int32]
    public let coreMLInput: CoreMLInput

    public init(prefixedText: String, tokenIDs: [Int32], coreMLInput: CoreMLInput) {
        self.prefixedText = prefixedText
        self.tokenIDs = tokenIDs
        self.coreMLInput = coreMLInput
    }
}
