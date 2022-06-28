// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI
@_exported import enum ApolloAPI.GraphQLEnum
@_exported import enum ApolloAPI.GraphQLNullable

public class CreateAwesomeReviewMutation: GraphQLMutation {
  public static let operationName: String = "CreateAwesomeReview"
  public static let document: DocumentType = .automaticallyPersisted(
    operationIdentifier: "4a1250de93ebcb5cad5870acf15001112bf27bb963e8709555b5ff67a1405374",
    definition: .init(
      """
      mutation CreateAwesomeReview {
        createReview(episode: JEDI, review: {stars: 10, commentary: "This is awesome!"}) {
          __typename
          stars
          commentary
        }
      }
      """
    ))

  public init() {}

  public struct Data: StarWarsAPI.SelectionSet {
    public let __data: DataDict
    public init(data: DataDict) { __data = data }

    public static var __parentType: ParentType { .Object(StarWarsAPI.Mutation.self) }
    public static var selections: [Selection] { [
      .field("createReview", CreateReview?.self, arguments: [
        "episode": "JEDI",
        "review": [
          "stars": 10,
          "commentary": "This is awesome!"
        ]
      ]),
    ] }

    public var createReview: CreateReview? { __data["createReview"] }

    /// CreateReview
    public struct CreateReview: StarWarsAPI.SelectionSet {
      public let __data: DataDict
      public init(data: DataDict) { __data = data }

      public static var __parentType: ParentType { .Object(StarWarsAPI.Review.self) }
      public static var selections: [Selection] { [
        .field("stars", Int.self),
        .field("commentary", String?.self),
      ] }

      public var stars: Int { __data["stars"] }
      public var commentary: String? { __data["commentary"] }
    }
  }
}