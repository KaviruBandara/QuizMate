/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The application delegate that handles events when the application launches.
Note: This file is now deprecated in favor of the SwiftUI App structure.
*/

import UIKit

// Note: AppDelegate is no longer used as the main entry point.
// The app now uses SwiftUI's @main attribute in FindingAnswersApp.swift
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
