//
//  ContentView.swift
//  SpeechRecognizerTodoApp
//
//  Created by ramil on 29.09.2020.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ToDo.created, ascending: true)], animation: .default) private var todos: FetchedResults<ToDo>
    
    @State private var recording = false
    
    @ObservedObject private var mic = MicMonitor(numberOfSamples: 30)
    
    private var speechManager = SpeechManager()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(todos) { item in
                        Text(item.text ?? " - ")
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationTitle("Speech Todo List")
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.7))
                    .padding()
                    .overlay(VStack {
                        visualizerView()
                    })
                    .opacity(recording ? 1 : 0)
                
                VStack {
                    recordButton()
                }
            }.onAppear() {
                speechManager.checkPermission()
            }
        }
    }
    
    private func recordButton() -> some View {
        Button(action: {
            addItem()
        }, label: {
            Image(systemName: recording ? "stop.fill" : "mic.fill")
                .font(.system(size: 40))
                .padding()
                .cornerRadius(10)
        }).foregroundColor(.red)
    }
    
    private func addItem() {
        if speechManager.isRecording {
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
        } else {
            self.recording = true
            mic.startMonitoring()
            speechManager.start { (speechText) in
                guard let text = speechText, !text.isEmpty else {
                    self.recording = false
                    return
                }
                
                DispatchQueue.main.async {
                    withAnimation {
                        let newItem = ToDo(context: viewContext)
                        newItem.id = UUID()
                        newItem.text = text
                        newItem.created = Date()
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        
        speechManager.isRecording.toggle()
    }
    
    private func normalizedSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50 / 2)
        return CGFloat(level * (100 / 25))
    }
    
    private func visualizerView() -> some View {
        VStack {
            HStack(spacing: 4) {
                ForEach(mic.soundSample, id: \.self) { level in
                    VisualBarView(value: self.normalizedSoundLevel(level: level))
                }
            }
        }
    }
    
    private func deleteItems(offset: IndexSet) {
        withAnimation {
            offset.map { todos[$0]}.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print(error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
