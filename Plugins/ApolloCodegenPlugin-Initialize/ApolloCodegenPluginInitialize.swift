import Foundation
import PackagePlugin

@main struct ApolloCodegenPluginInitialize: CommandPlugin {
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let process = Process()
    process.executableURL = try context.codegenExecutable
    process.arguments = ["init"] + arguments
    process.terminationHandler = Process.HandleErrorTermination

    try process.run()
    process.waitUntilExit()
  }
}
