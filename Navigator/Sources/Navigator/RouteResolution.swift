import SwiftUI

// MARK: - Route Resolution

public enum RouteResolution {
    case resolved(AnyView)
    case failed(RouteResolutionFailure)
}

public enum RouteResolutionFailure: Sendable, Equatable {
    case unregisteredRoute(key: String)
    case parameterTypeMismatch(key: String, expected: String, actual: String)

    public var routeKey: String {
        switch self {
        case .unregisteredRoute(let key):
            key
        case .parameterTypeMismatch(let key, _, _):
            key
        }
    }
}
