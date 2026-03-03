import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct WhstatsBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = WHStatsViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.menuTitle, systemImage: "clock") {
            MenuContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
