//
//  SpeechRecognizerTodoAppApp.swift
//  SpeechRecognizerTodoApp
//
//  Created by ramil on 29.09.2020.
//

import SwiftUI

@main
struct SpeechRecognizerTodoAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
