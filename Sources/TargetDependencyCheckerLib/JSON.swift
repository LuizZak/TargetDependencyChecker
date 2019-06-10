import Foundation

public enum JSON: Equatable {
    case dictionary([String: JSON])
    case array([JSON])
    case string(String)
    case number(Double)
    case bool(Bool)
    case `nil`

    public subscript(key key: String) -> JSON? {
        switch self {
        case .dictionary(let dict):
            return dict[key]
        default:
            return nil
        }
    }

    public subscript(index index: Int) -> JSON? {
        switch self {
        case .array(let array):
            return array[index]
        default:
            return nil
        }
    }

    /// Returns a `JSONSerialization`-compatible `Any`-valued type that can be
    /// freely converted with a `JSONSerialization` instance.
    public var asObject: Any {
        switch self {
        case .dictionary(let dict):
            return dict.mapValues { $0.asObject }
        case .array(let values):
            return values.map { $0.asObject }
        case .bool(let bool):
            if bool {
                return kCFBooleanTrue!
            } else {
                return kCFBooleanFalse!
            }
        case .number(let number):
            return NSNumber(value: number)
        case .string(let string):
            return string
        case .nil:
            return NSNull()
        }
    }
    
    public func decode<T: Decodable>(_ type: T.Type = T.self, decoder: JSONDecoder) throws -> T {
        return try decoder.decode(T.self, from: toData())
    }
    
    public func toData(options: JSONSerialization.WritingOptions = []) throws -> Data {
        return try JSONSerialization.data(withJSONObject: asObject, options: options)
    }
    
    public func toString(options: JSONSerialization.WritingOptions = []) throws -> String {
        let data = try toData(options: options)
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw Error.invalidJson
        }
        
        return string
    }
}

public extension JSON {
    typealias ValueMapper = (_ key: String, _ value: JSON) throws -> JSON

    /// Maps dictionary values, allowing replacement of values using a mapping
    /// closure.
    ///
    /// Dictionaries and arrays are traversed recursively during the mapping.
    ///
    /// - Parameter valueMapper: A closure which maps a `JSON` value, replacing
    /// dictionary values with the return value of this closure.
    /// - Returns: A new `JSON` instance, with all dictionary values replaced
    /// according to `valueMapper`.
    /// - Throws: Any error thrown within `valueMapper` closure.
    func mapDictionaryValuesRecursive(with valueMapper: ValueMapper) rethrows -> JSON {
        switch self {
        case .dictionary(var dict):
            for (key, value) in dict {
                let newValue = try value.mapDictionaryValuesRecursive(with: valueMapper)

                dict[key] = try valueMapper(key, newValue)
            }

            return .dictionary(dict)
        case .array(let array):
            return try .array(array.map { try $0.mapDictionaryValuesRecursive(with: valueMapper) })
        default:
            return self
        }
    }

    static func fromEncodable<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws -> JSON {
        let data = try encoder.encode(value)
        let object = try JSONSerialization.jsonObject(with: data, options: [])

        return try toJSON(object)
    }
    
    static func fromString(_ string: String, options: JSONSerialization.ReadingOptions = []) throws -> JSON {
        guard let data = string.data(using: .utf8) else {
            throw Error.invalidJsonString
        }
        
        return try fromData(data, options: options)
    }
    
    static func fromData(_ data: Data, options: JSONSerialization.ReadingOptions = []) throws -> JSON {
        let json = try JSONSerialization.jsonObject(with: data, options: options)
        return try JSON.toJSON(json)
    }
    
    /// Creates a JSON object from a given value.
    ///
    /// `value` must be a valid JSON-convertible value of either:
    ///
    /// 1. An NSDictionary-convertible of signature `[String: Any]`, where `Any`
    ///    is also a JSON-convertible value by this function;
    ///
    /// 2. An array-convertible of signature `[Any]`, where `Any` is also a
    ///    JSON-convertible value by this function;
    ///
    /// 3. An `NSNumber` representing a boolean value;
    ///
    /// 4. Any one of the number of values that are `Double`-convertible:
    ///    - `Int`;
    ///    - `UInt`;
    ///    - `Float`;
    ///    - `Double`.
    ///
    /// 5. A Swift `Bool` value;
    ///
    /// 6. An optional value consisting of `nil` or `NSNull` instance;
    ///
    /// - Throws: An `Error.invalidJson` error, in case the JSON object is invalid.
    static func toJSON(_ value: Any) throws -> JSON {
        switch value {
        case let dictionary as NSDictionary:
            var json: [String: JSON] = [:]
            for (key, value) in dictionary {
                guard let key = key as? String else {
                    throw Error.invalidJson
                }
                let jsonValue = try toJSON(value)
                json[key] = jsonValue
            }
            return JSON.dictionary(json)

        case let array as [Any]:
            return try JSON.array(array.map(toJSON))

        case let boolean as NSNumber where CFGetTypeID(boolean as CFTypeRef) == CFBooleanGetTypeID():
            return JSON.bool((boolean as CFBoolean) == kCFBooleanTrue)

        case let number as Int:
            return JSON.number(Double(number))

        case let number as UInt:
            return JSON.number(Double(number))

        case let number as Float:
            return JSON.number(Double(number))

        case let number as Double:
            return JSON.number(number)

        case let string as String:
            return JSON.string(string)

        case let bool as Bool:
            return JSON.bool(bool)

        case let value as Any? where value == nil:
            return JSON.nil

        case is NSNull:
            return JSON.nil

        default:
            throw Error.invalidJson
        }
    }

    enum Error: Swift.Error {
        case invalidJson
        case invalidJsonString
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension JSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSON)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}
