import Foundation
import GrowthBook

public let lazyExperimentationAPIHost = "https://experimentation.lazyweb.com"

public enum LazyExperimentationError: Error, Equatable {
    case invalidClientKey
    case invalidSubjectID
    case invalidEventName
    case invalidValue
    case invalidAPIHost
}

public final class LazyExperimentation {
    public let growthBook: GrowthBookSDK
    private let sender: EventSender

    public init(
        clientKey: String,
        subjectID: String,
        attributes: [String: Any] = [:],
        apiHost: String = lazyExperimentationAPIHost,
        preloadedFeatures: Data? = nil,
        session: URLSession = .shared
    ) throws {
        guard !clientKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LazyExperimentationError.invalidClientKey
        }
        guard Self.isOpaqueID(subjectID) else {
            throw LazyExperimentationError.invalidSubjectID
        }
        guard let host = URL(string: apiHost), host.scheme == "https", host.path.isEmpty else {
            throw LazyExperimentationError.invalidAPIHost
        }

        var userAttributes = attributes
        userAttributes["id"] = subjectID
        let sender = EventSender(
            clientKey: clientKey,
            subjectID: subjectID,
            attributes: userAttributes,
            apiHost: host,
            session: session
        )
        self.sender = sender
        self.growthBook = GrowthBookBuilder(
            apiHost: host.absoluteString,
            clientKey: clientKey,
            attributes: userAttributes,
            features: preloadedFeatures,
            trackingCallback: { experiment, result in
                sender.exposure(experimentKey: experiment.key, variationID: result.variationId)
            },
            backgroundSync: false
        ).initializer()
    }

    public func refresh() {
        growthBook.refreshCache()
    }

    public func capture(
        _ eventName: String,
        properties: [String: Any] = [:],
        value: Double? = nil
    ) throws {
        guard Self.isEventName(eventName) else {
            throw LazyExperimentationError.invalidEventName
        }
        guard value?.isFinite != false else {
            throw LazyExperimentationError.invalidValue
        }
        sender.capture(eventName: eventName, properties: properties, value: value)
    }

    private static func isOpaqueID(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 256 && !trimmed.contains("@")
    }

    private static func isEventName(_ value: String) -> Bool {
        value.range(of: "^[a-z0-9][a-z0-9._-]{0,127}$", options: .regularExpression) != nil
    }
}

private final class EventSender {
    private let clientKey: String
    private let subjectID: String
    private let attributes: [String: Any]
    private let apiHost: URL
    private let session: URLSession

    init(clientKey: String, subjectID: String, attributes: [String: Any], apiHost: URL, session: URLSession) {
        self.clientKey = clientKey
        self.subjectID = subjectID
        self.attributes = attributes
        self.apiHost = apiHost
        self.session = session
    }

    func exposure(experimentKey: String, variationID: Int) {
        send(
            eventName: "Experiment Viewed",
            properties: ["experimentId": experimentKey, "variationId": variationID]
        )
    }

    func capture(eventName: String, properties: [String: Any], value: Double?) {
        var payload = properties
        if let value { payload["value"] = value }
        send(eventName: eventName, properties: payload)
    }

    private func send(eventName: String, properties: [String: Any]) {
        var components = URLComponents(url: apiHost.appendingPathComponent("track"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "client_key", value: clientKey)]
        guard let url = components?.url else { return }
        let event: [String: Any] = [
            "event_name": eventName,
            "properties": properties,
            "attributes": attributes,
            "device_id": subjectID,
        ]
        guard JSONSerialization.isValidJSONObject([event]),
              let body = try? JSONSerialization.data(withJSONObject: [event]) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        session.dataTask(with: request).resume()
    }
}
