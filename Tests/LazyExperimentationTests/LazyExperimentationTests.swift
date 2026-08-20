import XCTest
@testable import LazyExperimentation

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) -> Void)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.handler?(request)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
        )!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{\"accepted\":1}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class LazyExperimentationTests: XCTestCase {
    func testGrowthBookOwnsAssignmentAndLazyCapturesOutcomes() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let tracked = expectation(description: "outcome tracked")
        MockURLProtocol.handler = { request in
            guard request.url?.path.contains("track") == true else { return }
            tracked.fulfill()
        }
        let features = Data(#"""
        {
          "new-onboarding": {
            "defaultValue": false,
            "rules": [{"variations": [false, true], "coverage": 1, "seed": "new-onboarding"}]
          }
        }
        """#.utf8)
        let experiments = try LazyExperimentation(
            clientKey: "lwe_cfg_test",
            subjectID: "ios-device-123",
            preloadedFeatures: features,
            session: session
        )

        _ = experiments.growthBook.getFeatureValue(feature: "new-onboarding", as: Bool.self, default: false)
        try experiments.capture("onboarding_completed", properties: ["steps": 3])

        wait(for: [tracked], timeout: 2)
    }
}
