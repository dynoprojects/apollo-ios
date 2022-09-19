// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI
@_exported import enum ApolloAPI.GraphQLEnum
@_exported import enum ApolloAPI.GraphQLNullable

public struct AuthorDetails: GitHubAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString { """
    fragment AuthorDetails on Actor {
      __typename
      login
      ... on User {
        __typename
        id
        name
      }
    }
    """ }

  public let __data: DataDict
  public init(data: DataDict) { __data = data }

  public static var __parentType: ParentType { GitHubAPI.Interfaces.Actor }
  public static var selections: [Selection] { [
    .field("login", String.self),
    .inlineFragment(AsUser.self),
  ] }

  /// The username of the actor.
  public var login: String { __data["login"] }

  public var asUser: AsUser? { _asInlineFragment() }

  /// AsUser
  ///
  /// Parent Type: `User`
  public struct AsUser: GitHubAPI.InlineFragment {
    public let __data: DataDict
    public init(data: DataDict) { __data = data }

    public static var __parentType: ParentType { GitHubAPI.Objects.User }
    public static var selections: [Selection] { [
      .field("id", ID.self),
      .field("name", String?.self),
    ] }

    public var id: ID { __data["id"] }
    /// The user's public profile name.
    public var name: String? { __data["name"] }
    /// The username of the actor.
    public var login: String { __data["login"] }
  }
}
