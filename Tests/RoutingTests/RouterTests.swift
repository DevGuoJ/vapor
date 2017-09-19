import HTTP
import Routing
import XCTest

class RouterTests: XCTestCase {
    func testRouter() throws {
        let router = TrieRouter()

        router.on(.get, to: "hello", "world") { req in
            return try Response(body: "hello")
        }

        router.on(.get, to: "foo", "bar", "baz") { req in
            return try Response(body: "foo")
        }

        router.on(.get, to: "users", User.parameter, "comments") { req in
            let bob = try req.parameters.next(User.self)
            XCTAssertEqual(bob.name, "bob")
            
            return try Response(body: "users!")
        }

        do {
            let request = Request(method: .get, uri: URI(path: "/foo/bar/baz"))
            let responder = router.route(request: request)

            XCTAssertNotNil(responder)
            let res = try responder!.respond(to: request)
            try XCTAssertEqual(String(data: res.blockingAwait().body.data, encoding: .utf8), "foo")
        }

        do {
            let request = Request(method: .get, uri: URI(path: "/hello/world"))
            let responder = router.route(request: request)

            XCTAssertNotNil(responder)
            let res = try responder!.respond(to: request)
            try XCTAssertEqual(String(data: res.blockingAwait().body.data, encoding: .utf8), "hello")
        }

        do {
            let request = Request(method: .get, uri: URI(path: "/users/bob/comments"))
            let responder = router.route(request: request)

            XCTAssertNotNil(responder)
            let res = try responder!.respond(to: request)
            try XCTAssertEqual(String(data: res.blockingAwait().body.data, encoding: .utf8), "users!")
        }
    }


    static let allTests = [
        ("testRouter", testRouter),
    ]
}

extension TrieRouter: SyncRouter { }

final class User: Parameter {
    static let uniqueSlug: String = "user"
    var name: String

    init(name: String) {
        self.name = name
    }

    static func make(for parameter: String, in request: Request) throws -> User {
        return User(name: parameter)
    }
}