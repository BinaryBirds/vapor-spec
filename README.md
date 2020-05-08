# Spec

Unit testing Vapor 4 applications through declarative specifications.


## Install

Add the repository as a dependency:

```swift
.package(url: "https://github.com/binarybirds/spec.git", from: "1.0.0"),
```

Add Spec to the target dependencies:

```swift
.product(name: "Spec", package: "spec"),
```

Update the packages and you are ready.

## Usage example

### Api

```swift
@testable import App
import Spec

final class BlogApiTests: XCTestCase {
    
    func testLogin(_ app: Application) throws {

        struct UserLoginRequest: Content {
            let email: String
            let password: String
        }
        struct UserTokenResponse: Content {
            let id: String
            let value: String
        }

        let userBody = UserLoginRequest(email: "foo@bar.com", password: "foo")
        
        var token: String?

        try app
            .describe("Login request should return ok")     // describe spec
            .post("/api/user/login")                        // post to endpoint
            .header("accept", "application/json")           // add header
            .body(userBody)                                 // add content body
            .expect(.ok)                                    // status code
            .expect(.json)                                  // media type
            .expect("content-length", ["81"])               // expect header
            .expect(UserTokenResponse.self) { content in    // expect content
                token = content.value                       // retreive content
            }
            .test(.inMemory)                                // test in memory

        _ = try XCTUnwrap(token)

    }
}
```


## License

[WTFPL](LICENSE) - Do what the fuck you want to.









