import XCTest
@testable import VaporSpec

final class VaporSpecTests: XCTestCase {

    func testStatusCode() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        try app
            .spec()
            .get("foo")
            .expect(.notFound)
            .test()
    }
    
    func testHeaderValues() throws {
        let app = Application(.testing)
        app.routes.get("hello") { _ in "hello" }
        defer { app.shutdown() }

        try app
            .spec()
            .get("hello")
            .expect("Content-Length", ["5"])
            .expect("Content-Type", ["text/plain; charset=utf-8"])
            .test()
    }
    
    func testContentTypeHeader() throws {
        let app = Application(.testing)
        app.routes.get("hello") { _ in "hello" }
        defer { app.shutdown() }

        try app
            .spec()
            .get("hello")
            .expect("text/plain; charset=utf-8")
            .test()
    }
    
    func testBodyValue() throws {
        let app = Application(.testing)
        app.routes.get("hello") { _ in "hello" }
        defer { app.shutdown() }

        try app
            .spec()
            .get("hello")
            .expect(closure: { res in
                let string = res.body.string
                XCTAssertEqual(string, "hello")
            })
            .test()
    }
    
    func testJSON() throws {
        struct Test: Codable, Content {
            let foo: String
            let bar: Int
            let baz: Bool
        }

        let app = Application(.testing)
        app.routes.post("foo") { req in try req.content.decode(Test.self) }
        defer { app.shutdown() }

        let input = Test(foo: "foo", bar: 42, baz: true)
        try app
            .spec()
            .post("foo")
            .json(input, Test.self) { res in
                XCTAssertEqual(input.foo, res.foo)
                XCTAssertEqual(input.bar, res.bar)
                XCTAssertEqual(input.baz, res.baz)
            }
            .test()
    }
}
