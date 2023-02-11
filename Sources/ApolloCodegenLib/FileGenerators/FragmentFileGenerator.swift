import Foundation

/// Generates a file containing the Swift representation of a [GraphQL Fragment](https://spec.graphql.org/draft/#sec-Language.Fragments).
struct FragmentFileGenerator: FileGenerator {
  /// Source IR fragment.
  let irFragment: IR.NamedFragment
  /// Source IR schema.
  let schema: IR.Schema
  /// Shared codegen configuration.
  let config: ApolloCodegen.ConfigurationContext
  
  var template: TemplateRenderer { FragmentTemplate(
    fragment: irFragment,
    schema: schema,
    config: config
  ) }
  var target: FileTarget { .fragment(irFragment.definition) }

  // cpiro: lmao ensure generated fragment files and object files have distinct names so
  // `fragment NetworkReferrerData on NetworkReferrerData` doesn't fuck up the whole game
  //
  //   error: filename "NetworkReferrerData.swift" used twice: ...
  //   note: filenames are used to distinguish private declarations with the same name
  //        -- Xcode choke of the century
  //
  var fileName: String { irFragment.definition.name + "-Fragment" }
}
