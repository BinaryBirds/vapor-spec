public extension Application {
    /// creates a new spec with a given name
    func describe(_ name: String) -> Spec {
        .init(name: name, app: self)
    }
}

/// a spec object to describe test cases
public final class Spec {

    private unowned var app: Application

    private var name: String
    private var method: HTTPMethod = .GET
    private var path: String = ""
    private var bearerToken: String? = nil
    private var headers: HTTPHeaders = [:]
    private var buffer: ByteBuffer? = nil
    private var beforeRequests: [(inout XCTHTTPRequest) throws -> ()] = []
    private var expectations: [(XCTHTTPResponse) throws -> ()] = []
    
    private func beforeRequest() -> (inout XCTHTTPRequest) throws -> () {
        { [unowned self] req in
            for item in beforeRequests {
                try item(&req)
            }
        }
    }

    internal init(name: String, app: Application) {
        self.name = name
        self.app = app
    }

    /// set the HTTPMethod and request path
    public func on(_ method: HTTPMethod, _ path: String) -> Self {
        self.method = method
        self.path = path
        return self
    }
    
    ///set the request method to GET and the path to the given value
    public func get(_ path: String) -> Self { self.on(.GET, path) }
    ///set the request method to POST and the path to the given value
    public func post(_ path: String) -> Self { self.on(.POST, path) }
    ///set the request method to PUT and the path to the given value
    public func put(_ path: String) -> Self { self.on(.PUT, path) }
    ///set the request method to PATCH and the path to the given value
    public func patch(_ path: String) -> Self { self.on(.PATCH, path) }
    ///set the request method to DELETE and the path to the given value
    public func delete(_ path: String) -> Self { self.on(.DELETE, path) }

    ///set a bearer token Authorization header
    public func bearerToken(_ token: String) -> Self {
        self.headers.replaceOrAdd(name: "Authorization", value:  "Bearer \(token)")
        return self
    }
    
    ///set a header value
    public func header(_ name: String, _ value: String) -> Self {
        self.headers.replaceOrAdd(name: name, value: value)
        return self
    }
    
    ///set a buffer as the request body
    public func buffer(_ buffer: ByteBuffer) -> Self {
        self.buffer = buffer
        return self
    }
    
    ///set a content as the request body
    public func cookie(_ cookie: HTTPCookies?) -> Self {
        guard let cookie = cookie else {
            return self
        }
        self.beforeRequests.append({ req in
            req.headers.cookie = cookie
        })
        return self
    }

    ///set a content as the request body
    public func body<T: Content>(_ body: T) -> Self {
        self.beforeRequests.append({ req in
            try req.content.encode(body)
        })
        return self
    }

    ///expect a specific HTTPStatus
    public func expect(_ status: HTTPStatus, file: StaticString = #file, line: UInt = #line) -> Self {
        self.expectations.append({ res in
            XCTAssertEqual(res.status, status, file: file, line: line)
        })
        return self
    }

    ///expect a specific header
    public func expect(_ headerName: String, _ values: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Self {
        self.expectations.append({ res in
            XCTAssertTrue(res.headers.contains(name: headerName))
            if let expectedValues = values {
                let headerValues = res.headers[headerName]
                XCTAssertEqual(headerValues, expectedValues, file: file, line: line)
            }
        })
        return self
    }

    ///expect a specific HTTPMediaType
    public func expect(_ mediaType: HTTPMediaType, file: StaticString = #file, line: UInt = #line) -> Self {
        self.expectations.append({ res in
            XCTAssertEqual(try XCTUnwrap(res.headers.contentType), mediaType, file: file, line: line)
        })
        return self
    }

    ///expect a specific Content type, the decoded content will be available in the closure block
    public func expect<T: Content>(_ contentType: T.Type, file: StaticString = #file, line: UInt = #line, closure: @escaping ((T) -> ()) = { _ in }) -> Self {
        self.expectations.append({ res in
            XCTAssertContent(contentType, res, file: file, line: line, closure)
        })
        return self
    }

    /// expect a byte buffer as a response
    public func expect(file: StaticString = #file, line: UInt = #line, closure: @escaping ((XCTHTTPResponse) throws -> ()) = { _ in }) -> Self {
        self.expectations.append({ res in
            try closure(res)
        })
        return self
    }

    ///test the given spec using a test method (in memory or via a running server), default is in memory
    public func test(_ method: Application.Method = .inMemory, file: StaticString = #file, line: UInt = #line) throws {
        let afterRequest: (XCTHTTPResponse) throws -> () = { res in
            for expectation in self.expectations {
                try expectation(res)
            }
        }

        try self.app.testable(method: method)
            .test(self.method,
                  self.path,
                  headers: self.headers,
                  body: self.buffer,
                  file: file,
                  line: line,
                  beforeRequest: self.beforeRequest(),
                  afterResponse: afterRequest)
    }
}
