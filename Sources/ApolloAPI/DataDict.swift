/// A structure that wraps the underlying data dictionary used by `SelectionSet`s.

import Foundation

public struct DataDict: Hashable {

  public var _data: JSONObject
  public let _variables: GraphQLOperation.Variables?

  public init(
    _ data: JSONObject,
    variables: GraphQLOperation.Variables?
  ) {
    self._data = data
    self._variables = variables
  }

  @inlinable public subscript<T: AnyScalarType & Hashable>(_ key: String) -> T {
    get {
      func warnOrExit() {
        print("*** BAD DataDict subscript ***", _data[key] ?? "(nil)", T.self, _data[key] as? T ?? "(nil)")
#if DEBUG
        fatalError("*** bad DataDict subscript ***")
#endif
      }

      if T.self == Date.self {
        if let value = _data[key] as? String {
          do {
            return try Date(value, strategy: .iso8601) as! T
          } catch {
            warnOrExit()
            return Date() as! T
          }
        } else {
          warnOrExit()
          return Date() as! T
        }
      } else if T.self == Optional<Date>.self {
        guard let value = _data[key] as? String else { return Optional<Date>.none as! T }
        do {
          return try Date(value, strategy: .iso8601
            .year()
            .month()
            .day()
            .time(includingFractionalSeconds: true)
            .timeZone(separator: .omitted)) as! T
        } catch {
          warnOrExit()
          return Date() as! T
        }
      } else if let value = _data[key] as? T {
        return value
      } else {
        if T.self == String.self {
          warnOrExit()
          return "" as! T
        } else if T.self == Int.self {
          warnOrExit()
          return 0 as! T
        } else if T.self == Bool.self {
          warnOrExit()
          return false as! T
        } else if T.self == Float.self {
          warnOrExit()
          return 0.0 as! T
        } else if T.self == Double.self {
          warnOrExit()
          return 0.0 as! T
        } else {
          warnOrExit()
          fatalError("*** bad DataDict subscript ***")
        }
      }
    }
    set { _data[key] = newValue }
    _modify {
      var value = _data[key] as! T
      defer { _data[key] = value }
      yield &value
    }
  }

  @inlinable public subscript<T: SelectionSetEntityValue>(_ key: String) -> T {
    get { T.init(fieldData: _data[key], variables: _variables) }
    set { _data[key] = newValue._fieldData }
    _modify {
      var value = T.init(fieldData: _data[key], variables: _variables)
      defer { _data[key] = value._fieldData }
      yield &value
    }
  }

  @inlinable public func hash(into hasher: inout Hasher) {
    hasher.combine(_data)
    hasher.combine(_variables?._jsonEncodableValue?._jsonValue)
  }

  @inlinable public static func ==(lhs: DataDict, rhs: DataDict) -> Bool {
    lhs._data == rhs._data &&
    lhs._variables?._jsonEncodableValue?._jsonValue == rhs._variables?._jsonEncodableValue?._jsonValue
  }
}

public protocol SelectionSetEntityValue {
  init(fieldData: AnyHashable?, variables: GraphQLOperation.Variables?)
  var _fieldData: AnyHashable { get }
}

extension AnySelectionSet {
  @inlinable public init(fieldData: AnyHashable?, variables: GraphQLOperation.Variables?) {
    guard let fieldData = fieldData as? JSONObject else {
      fatalError("\(Self.self) expected data for entity.")
    }
    self.init(data: DataDict(fieldData, variables: variables))
  }

  @inlinable public var _fieldData: AnyHashable { __data._data }
}

extension Optional: SelectionSetEntityValue where Wrapped: SelectionSetEntityValue {
  @inlinable public init(fieldData: AnyHashable?, variables: GraphQLOperation.Variables?) {
    guard case let .some(fieldData) = fieldData else {
      self = .none
      return
    }
    self = .some(Wrapped.init(fieldData: fieldData, variables: variables))
  }

  @inlinable public var _fieldData: AnyHashable { map(\._fieldData) }
}

extension Array: SelectionSetEntityValue where Element: SelectionSetEntityValue {
  @inlinable public init(fieldData: AnyHashable?, variables: GraphQLOperation.Variables?) {
    guard let fieldData = fieldData as? [AnyHashable?] else {
      fatalError("\(Self.self) expected list of data for entity.")
    }
    self = fieldData.map { Element.init(fieldData:$0, variables: variables) }
  }

  @inlinable public var _fieldData: AnyHashable { map(\._fieldData) }
}
