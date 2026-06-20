public enum TokenIDConverter {
    public static func int32TokenIDs(from tokenIDs: [Int]) throws -> [Int32] {
        try tokenIDs.map { tokenID in
            guard tokenID >= Int(Int32.min), tokenID <= Int(Int32.max) else {
                throw EmbeddingError.tokenIDOutOfInt32Range(tokenID)
            }

            return Int32(tokenID)
        }
    }
}
