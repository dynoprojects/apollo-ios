import Foundation
import ApolloUtils

/// Provides the format to convert a [GraphQL Custom Scalar](https://spec.graphql.org/draft/#sec-Scalars.Custom-Scalars)
/// into Swift code.
struct CustomScalarTemplate: TemplateRenderer {
  /// IR representation of source [GraphQL Custom Scalar](https://spec.graphql.org/draft/#sec-Scalars.Custom-Scalars).
  let graphqlScalar: GraphQLScalarType

  let config: ApolloCodegen.ConfigurationContext

  let target: TemplateTarget = .schemaFile

  var headerTemplate: TemplateString? {
    TemplateString(
    """
    // @generated
    """
    // > This file was automatically generated and can be edited to implement
    // > advanced custom scalar functionality.
    // >
    // > Any changes to this file will not be overwritten by future
    // > code generation execution.
    //
    // [cpiro] ... lol, no. We're not going to put custom code in the
    // __generated__ directory, and we're certainly not going to rely on any
    // shitty logic that protects changes to this file. afaict the codegen
    // script doesn't remove any old files, so we should `rm -rf` the old
    // gencode to be sure no old cruft remains. I'd remove these files
    // altogether, but it'll be convenient to know which custom scalars are
    // referenced at a glance -- you'll notice a new generated file if you
    // reference a new scalar.
    )
  }

  var template: TemplateString {
    TemplateString(
    """
    \(documentation: documentationTemplate, config: config)
    \(embeddedAccessControlModifier)\
    // typealias \(graphqlScalar.name.firstUppercased) = String

    """
    )
  }

  private var documentationTemplate: String? {
    var string = graphqlScalar.documentation
    if let specifiedByURL = graphqlScalar.specifiedByURL {
      let specifiedByDocs = "Specified by: [](\(specifiedByURL))"
      string = string?.appending("\n\n\(specifiedByDocs)") ?? specifiedByDocs
    }
    return string
  }
}
