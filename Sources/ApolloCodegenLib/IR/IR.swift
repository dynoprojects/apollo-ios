import OrderedCollections
import CryptoKit
import Foundation
import Darwin

// lmfao it works
func canonicalizeQuery(_ query: String) -> String {
  let components = query
    .replacingOccurrences(of: "{", with: " { ")
    .replacingOccurrences(of: "}", with: " } ")
    .replacingOccurrences(of: "(", with: " ( ")
    .replacingOccurrences(of: ")", with: " ) ")
    .replacingOccurrences(of: ",", with: "")
    .components(separatedBy: .whitespacesAndNewlines)
  return components
    .filter { !$0.isEmpty && $0 != "__typename" }
    .sorted()
    .joined(separator: " ")
}

var opIdsFromWeb: [String: String] = [:]
struct NopeError1: Error {}
struct NopeError2: Error {}
struct NopeError3: Error {}
struct NopeError4: Error {}

//

class IR {
  let compilationResult: CompilationResult

  let schema: Schema

  let fieldCollector = FieldCollector()

  var builtFragments: [String: NamedFragment] = [:]

  init(schemaName: String, compilationResult: CompilationResult) {
    self.compilationResult = compilationResult
    self.schema = Schema(
      name: schemaName,
      referencedTypes: .init(compilationResult.referencedTypes),
      documentation: compilationResult.schemaDocumentation
    )
    assert(opIdsFromWeb.isEmpty)
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/cpiro/a/braid/web/packages/api-server/server-query-ids.json"), options: .mappedIfSafe)
      let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
      guard let jsonResult = jsonResult as? Dictionary<String, AnyObject> else {
        throw NopeError1()
      }

      for (hash, inside) in jsonResult {
        guard let query = inside["query"] as? String else {
          throw NopeError2()
        }
        guard let archivedOn = inside["archivedOn"] as? Int? else {
          throw NopeError4()
        }
        if archivedOn == nil {
          let canon = canonicalizeQuery(query)
          print(hash, canon)
          if opIdsFromWeb[canon] != nil {
            print("jfc")
            print(query)
            print(opIdsFromWeb[canon])
            print(canon)
            throw NopeError3() // two queries canon'd down to the same string
          } else {
            opIdsFromWeb[canon] = hash
          }
        }
      }
      print("\n-----------------------------------------\n")
    } catch {
      print(error)
      exit(1)
    }
  }

  /// Represents a concrete entity in an operation or fragment that fields are selected upon.
  ///
  /// Multiple `SelectionSet`s may select fields on the same `Entity`. All `SelectionSet`s that will
  /// be selected on the same object share the same `Entity`.
  class Entity {
    struct FieldPathComponent: Hashable {
      let name: String
      let type: GraphQLType
    }
    typealias FieldPath = LinkedList<FieldPathComponent>

    /// The selections that are selected for the entity across all type scopes in the operation.
    /// Represented as a tree.
    let selectionTree: EntitySelectionTree

    /// A list of path components indicating the path to the field containing the `Entity` in
    /// an operation or fragment.
    let fieldPath: FieldPath

    var rootTypePath: LinkedList<GraphQLCompositeType> { selectionTree.rootTypePath }

    var rootType: GraphQLCompositeType { rootTypePath.last.value }

    init(
      rootTypePath: LinkedList<GraphQLCompositeType>,
      fieldPath: FieldPath
    ) {
      self.selectionTree = EntitySelectionTree(rootTypePath: rootTypePath)
      self.fieldPath = fieldPath
    }
  }

  class Operation {
    let definition: CompilationResult.OperationDefinition

    /// The root field of the operation. This field must be the root query, mutation, or
    /// subscription field of the schema.
    let rootField: EntityField

    /// All of the fragments that are referenced by this operation's selection set.
    let referencedFragments: OrderedSet<NamedFragment>

    lazy var operationIdentifier: String = {
      let queryParts = referencedFragments.map(\.definition.source) + [definition.source]
      let query = canonicalizeQuery(queryParts.joined(separator: " "))

      if let id = opIdsFromWeb[query] {
        //print(id, query)
        return id
      } else {
        print("????????????????????????????????????????????????????????????????", query)
        exit(1)
      }
    }()

    init(
      definition: CompilationResult.OperationDefinition,
      rootField: EntityField,
      referencedFragments: OrderedSet<NamedFragment>
    ) {
      self.definition = definition
      self.rootField = rootField
      self.referencedFragments = referencedFragments
    }
  }

  class NamedFragment: Hashable, CustomDebugStringConvertible {
    let definition: CompilationResult.FragmentDefinition
    let rootField: EntityField

    /// All of the fragments that are referenced by this fragment's selection set.
    let referencedFragments: OrderedSet<NamedFragment>

    /// All of the Entities that exist in the fragment's selection set,
    /// keyed by their relative response path within the fragment.
    ///
    /// - Note: The FieldPath for an entity within a fragment will begin with a path component
    /// with the fragment's name and type.
    let entities: [IR.Entity.FieldPath: IR.Entity]

    var name: String { definition.name }
    var type: GraphQLCompositeType { definition.type }

    init(
      definition: CompilationResult.FragmentDefinition,
      rootField: EntityField,
      referencedFragments: OrderedSet<NamedFragment>,
      entities: [IR.Entity.FieldPath: IR.Entity]
    ) {
      self.definition = definition
      self.rootField = rootField
      self.referencedFragments = referencedFragments
      self.entities = entities
    }

    static func == (lhs: IR.NamedFragment, rhs: IR.NamedFragment) -> Bool {
      lhs.definition == rhs.definition &&
      lhs.rootField === rhs.rootField
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(definition)
      hasher.combine(ObjectIdentifier(rootField))
    }

    var debugDescription: String {
      definition.debugDescription
    }
  }

  /// Represents a Fragment that has been "spread into" another SelectionSet using the
  /// spread operator (`...`).
  ///
  /// While a `NamedFragment` can be shared between operations, a `FragmentSpread` represents a
  /// `NamedFragment` included in a specific operation.
  class FragmentSpread: Hashable, CustomDebugStringConvertible {

    /// The `NamedFragment` that this fragment refers to.
    ///
    /// This is a fragment that has already been built. To "spread" the fragment in, it's entity
    /// selection trees are merged into the entity selection trees of the operation/fragment it is
    /// being spread into. This allows merged field calculations to include the fields merged in
    /// from the fragment.
    let fragment: NamedFragment

    /// Indicates the location where the fragment has been "spread into" its enclosing
    /// operation/fragment. It's `scopePath` and `entity` reference are scoped to the operation it
    /// belongs to.
    let typeInfo: SelectionSet.TypeInfo

    var inclusionConditions: AnyOf<InclusionConditions>?

    var definition: CompilationResult.FragmentDefinition { fragment.definition }

    init(
      fragment: NamedFragment,
      typeInfo: SelectionSet.TypeInfo,
      inclusionConditions: AnyOf<InclusionConditions>?
    ) {
      self.fragment = fragment
      self.typeInfo = typeInfo
      self.inclusionConditions = inclusionConditions
    }

    static func == (lhs: IR.FragmentSpread, rhs: IR.FragmentSpread) -> Bool {
      lhs.fragment === rhs.fragment &&
      lhs.typeInfo == rhs.typeInfo &&
      lhs.inclusionConditions == rhs.inclusionConditions
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(fragment))
      hasher.combine(typeInfo)
      hasher.combine(inclusionConditions)
    }

    var debugDescription: String {
      var description = fragment.debugDescription
      if let inclusionConditions = inclusionConditions {
        description += " \(inclusionConditions.debugDescription)"
      }
      return description
    }
  }

}
