// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension MyGraphQLSchema.Objects {
  static let Dog = Object(
    typename: "Dog",
    implementedInterfaces: [
      MyGraphQLSchema.Interfaces.Animal.self,
      MyGraphQLSchema.Interfaces.Pet.self,
      MyGraphQLSchema.Interfaces.HousePet.self,
      MyGraphQLSchema.Interfaces.WarmBlooded.self
    ]
  )
}