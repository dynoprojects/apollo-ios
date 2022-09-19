import Foundation
import PackagePlugin

@main struct ApolloCodegenPluginFetch: CommandPlugin {
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let process = Process()
    process.executableURL = try context.codegenExecutable
    process.arguments = ["fetch-schema"] + arguments
    process.terminationHandler = Process.HandleErrorTermination

    try process.run()
    process.waitUntilExit()
  }
}
