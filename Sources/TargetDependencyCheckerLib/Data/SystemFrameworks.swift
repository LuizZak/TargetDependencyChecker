/// Contains a list of frameworks that are system-wide and should not be
/// considered when checking a dependency graph.
public enum SystemFrameworks {
    public static let frameworks: Set<String> = [
        "CDispatch",
        "CFURLSessionInterface",
        "CFXMLInterface",
        "CoreFoundation",
        "CUUID",
        "Darwin",
        "Dispatch",
        "Dispatch",
        "DispatchIntrospection",
        "Distributed",
        "Foundation",
        "Foundation",
        "FoundationNetworking",
        "FoundationXML",
        "Glibc",
        "ObjectiveC",
        "RegexBuilder",
        "Swift",
        "SwiftGlibc",
        "SwiftOverlayShims",
        "WinSDK",
        "XCTest",
    ]
}
