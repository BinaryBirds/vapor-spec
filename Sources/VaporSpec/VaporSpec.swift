public extension Application {
    /// creates a new spec with a given name
    func spec(_ name: String = #function) -> VaporSpec {
        .init(name: name, app: self)
    }
}

/// a spec object to describe test cases
public final class VaporSpec {
    
    private unowned var app: Application
    
    private var name: String
    private var method: HTTPMethod = .GET
    private var path: String = ""
    private var bearerToken: String? = nil
    private var headers: HTTPHeaders = [:]
    private var buffer: ByteBuffer? = nil
    private var beforeRequests: [(inout XCTHTTPRequest) throws -> ()] = []
    private var expectations: [(XCTHTTPResponse) throws -> ()] = []

    internal init(name: String, app: Application) {
        self.name = name
        self.app = app
    }
    
    private func beforeRequest() -> (inout XCTHTTPRequest) throws -> () {
        { [unowned self] req in
            for item in beforeRequests {
                try item(&req)
            }
        }
    }
}

public extension VaporSpec {
    
    /// set the HTTPMethod and request path
    func on(_ method: HTTPMethod, _ path: String) -> Self {
        self.method = method
        self.path = path
        return self
    }
    
    ///set the request method to GET and the path to the given value
    func get(_ path: String) -> Self { on(.GET, path) }
    ///set the request method to POST and the path to the given value
    func post(_ path: String) -> Self { on(.POST, path) }
    ///set the request method to PUT and the path to the given value
    func put(_ path: String) -> Self { on(.PUT, path) }
    ///set the request method to PATCH and the path to the given value
    func patch(_ path: String) -> Self { on(.PATCH, path) }
    ///set the request method to DELETE and the path to the given value
    func delete(_ path: String) -> Self { on(.DELETE, path) }
    
}

public extension VaporSpec {
    
    ///set a header value
    func header(_ name: String, _ value: String) -> Self {
        headers.replaceOrAdd(name: name, value: value)
        return self
    }
    
    ///set a bearer token Authorization header
    func bearerToken(_ token: String) -> Self {
        headers.replaceOrAdd(name: "Authorization", value:  "Bearer \(token)")
        return self
    }
    
    ///set a buffer as the request body
    func buffer(_ buffer: ByteBuffer) -> Self {
        self.buffer = buffer
        return self
    }

    ///set a content as the request body
    func body<T: Content>(_ body: T) -> Self {
        beforeRequests.append({ req in
            try req.content.encode(body)
        })
        return self
    }
    
    ///set a content as the request body
    func cookie(_ cookie: HTTPCookies?) -> Self {
        guard let cookie = cookie else {
            return self
        }
        beforeRequests.append({ req in
            req.headers.cookie = cookie
        })
        return self
    }
}

public extension VaporSpec {
    
    ///expect a specific HTTPStatus
    func expect(
        file: StaticString = #file,
        line: UInt = #line,
        _ status: HTTPStatus
    ) -> Self {
        expectations.append({ res in
            XCTAssertEqual(res.status, status, file: file, line: line)
        })
        return self
    }
    
    ///expect a specific header
    func expect(
        file: StaticString = #file,
        line: UInt = #line,
        _ header: String,
        _ values: [String]? = nil
    ) -> Self {
        expectations.append({ res in
            XCTAssertTrue(res.headers.contains(name: header))
            if let expectedValues = values {
                let headerValues = res.headers[header]
                XCTAssertEqual(headerValues, expectedValues, file: file, line: line)
            }
        })
        return self
    }
    
    ///expect a specific HTTPMediaType
    func expect(
        file: StaticString = #file,
        line: UInt = #line,
        _ contentType: String
    ) -> Self {
        expectations.append({ res in
            XCTAssertEqual(
                try XCTUnwrap(res.headers.contentType).description,
                contentType,
                file: file,
                line: line
            )
        })
        return self
    }
    
    ///expect a specific Content type, the decoded content will be available in the closure block
    func expect<T: Content>(
        file: StaticString = #file,
        line: UInt = #line,
        _ contentType: T.Type,
        closure: @escaping ((T) -> ()) = { _ in }
    ) -> Self {
        expectations.append({ res in
            XCTAssertContent(contentType, res, file: file, line: line, closure)
        })
        return self
    }
    
    /// expect a byte buffer as a response
    func expect(
        file: StaticString = #file,
        line: UInt = #line,
        closure: @escaping ((XCTHTTPResponse) throws -> ()) = { _ in }
    ) -> Self {
        expectations.append({ res in
            try closure(res)
        })
        return self
    }
    
    
}

public extension VaporSpec {
    
    func json<T: Content, U: Content>(
        encoder: JSONEncoder? = nil,
        decoder: JSONDecoder? = nil,
        status: HTTPResponseStatus = .ok,
        _ data: T,
        _ type: U.Type,
        _ block: @escaping ((U) -> Void)
    ) throws -> Self {
        self
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .body(data)
            .expect(status)
            .expect("application/json; charset=utf-8")
            .expect(U.self) { object in
                block(object)
            }
    }
    
    func json<T: Content>(
        encoder: JSONEncoder? = nil,
        status: HTTPResponseStatus = .ok,
        _ data: T,
        _ block: @escaping ((XCTHTTPResponse) -> Void)
    ) throws -> Self {
        self
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .body(data)
            .expect(status)
            .expect { object in
                block(object)
            }
    }
    
    func json<U: Content>(
        decoder: JSONDecoder? = nil,
        status: HTTPResponseStatus = .ok,
        _ type: U.Type,
        _ block: @escaping ((U) -> Void)
    ) -> Self {
        self
            .header("Accept", "application/json")
            .expect(status)
            .expect("application/json; charset=utf-8")
            .expect(U.self) { object in
                block(object)
            }
    }
}

public extension VaporSpec {

    ///test the given spec using a test method (in memory or via a running server), default is in memory
    func test(
        file: StaticString = #file,
        line: UInt = #line,
        _ method: Application.Method = .inMemory
    ) throws {
        let afterRequest: (XCTHTTPResponse) throws -> () = { [unowned self] res in
            for expectation in self.expectations {
                try expectation(res)
            }
        }
        try self.app.testable(method: method)
            .test(
                self.method,
                path,
                headers: headers,
                body: buffer,
                file: file,
                line: line,
                beforeRequest: beforeRequest(),
                afterResponse: afterRequest
            )
    }
}
