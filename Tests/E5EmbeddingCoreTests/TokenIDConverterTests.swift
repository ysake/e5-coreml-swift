import E5EmbeddingCore
import XCTest

final class TokenIDConverterTests: XCTestCase {
    func testConvertsIntTokenIDsToInt32() throws {
        let converted = try TokenIDConverter.int32TokenIDs(from: [0, 1, 250002])

        XCTAssertEqual(converted, [0, 1, 250002])
    }

    func testRejectsTokenIDsOutsideInt32Range() {
        let tooLarge = Int(Int32.max) + 1

        XCTAssertThrowsError(try TokenIDConverter.int32TokenIDs(from: [tooLarge])) { error in
            XCTAssertEqual(error as? EmbeddingError, .tokenIDOutOfInt32Range(tooLarge))
        }
    }
}
