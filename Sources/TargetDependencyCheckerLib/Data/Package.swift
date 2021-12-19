struct Package: Decodable {
    var name: String
    var targets: [Target]
}
