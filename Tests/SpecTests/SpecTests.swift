import XCTest
@testable import Spec

final class SpecTests: XCTestCase {

    func testExample() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        /// configure dummy path
        app.get("lorem-ipsum") { _ in "Lorem ipsum" }

        /// test dummy path
        try app.describe("Lorem ipsum dolor sit amet")
            .get("/lorem-ipsum/")
            .expect(.ok)
            .expect { res in
                XCTAssertEqual(res.body.string, "Lorem ipsum")
            }
            .test(.inMemory)
    }
}
