import SwiftUI
import AVFoundation
import Combine

// UIViewRepresentable for UITextField
struct NumberField: UIViewRepresentable {
    @Binding var value: Int
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = String(value)
        uiView.placeholder = placeholder
    }

    func makeCoordinator() -> NumberFieldCoordinator {
        NumberFieldCoordinator(self)
    }
}

class NumberFieldCoordinator: NSObject, UITextFieldDelegate {
    var parent: NumberField

    init(_ parent: NumberField) {
        self.parent = parent
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        if let intValue = Int(updatedText) {
            parent.value = intValue
            return true
        } else if updatedText.isEmpty {
            parent.value = 0
            return true
        }
        return false
    }
}

struct WorkoutDurationView: View {
    @State private var workoutDuration: Int = 0
    
    var body: some View {
        VStack {
            NumberField(value: $workoutDuration, placeholder: "Workout Duration")
            NavigationLink(destination: RestDurationView(workoutDuration: workoutDuration)) {
                Text("Next")
            }
        }.padding()
    }
}

struct RestDurationView: View {
    var workoutDuration: Int
    @State private var restDuration: Int = 0
    
    var body: some View {
        VStack {
            NumberField(value: $restDuration, placeholder: "Rest Duration")
            NavigationLink(destination: CountdownView(workoutDuration: workoutDuration, restDuration: restDuration)) {
                Text("Next")
            }
        }.padding()
    }
}

struct CountdownView: View {
    var workoutDuration: Int
    var restDuration: Int
    @State private var countdown: Int = 0
    
    var body: some View {
        VStack {
            NumberField(value: $countdown, placeholder: "Countdown")
            NavigationLink(destination: RepetitionsView(workoutDuration: workoutDuration, restDuration: restDuration, countdown: countdown)) {
                Text("Next")
            }
        }.padding()
    }
}

struct RepetitionsView: View {
    var workoutDuration: Int
    var restDuration: Int
    var countdown: Int
    @State private var reps: Int = 0
    
    var body: some View {
        VStack {
            NumberField(value: $reps, placeholder: "Repetitions")
            NavigationLink(destination: ContentView(onSeconds: workoutDuration, offSeconds: restDuration, countdownSeconds: countdown, reps: reps)) {
                Text("Start Workout")
            }
        }.padding()
    }
}

struct ContentView: View {
    @State var onSeconds: Int
    @State var offSeconds: Int
    @State var countdownSeconds: Int
    @State var reps: Int
    
    // State variable for pause feature
    @State private var isVolumeOn = UserDefaults.standard.bool(forKey: "isVolumeOn")
    @State private var isCountingDown = false
    @State private var isWorkingOut = false
    @State private var isResting = false
    @State private var isWorkoutComplete = false
    @State private var isWorkoutAlertShown = false
    @State private var isPaused = false
    
    @State private var cancellable: AnyCancellable?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle(isOn: $isVolumeOn) {
                Text("Sound")
            }
            
            Button(action: { self.startWorkout() }) {
                Text("Start")
            }
            
            Button(action: { self.isPaused.toggle() }) { // New pause button
                Text(isPaused ? "Resume" : "Pause")
            }
            
            if isCountingDown {
                Text("\(countdownSeconds)")
            } else if isWorkingOut {
                Text("Workout: \(onSeconds)")
            } else if isResting {
                Text("Rest: \(offSeconds)")
            }
            
            if isWorkoutComplete {
                Text("Done").onAppear {
                    isWorkoutAlertShown = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        isWorkoutAlertShown = false
                    }
                }.alert(isPresented: $isWorkoutAlertShown, content: {
                    Alert(title: Text("Done"), dismissButton: .default(Text("OK")))
                })
            }
        }
        .onAppear {
            // Start timer when the view appears.
            self.cancellable = timer
                .sink { _ in
                    self.timerTick()
                }
        }
        .onDisappear {
            // Cancel timer when the view disappears.
            self.cancellable?.cancel()
        }
    }
    
    private func startWorkout() {
        if onSeconds > 0 && offSeconds > 0 && reps > 0 {
            isCountingDown = true
        }
    }
    
    private func timerTick() {
        if isPaused { return }
        if isCountingDown {
            if countdownSeconds > 0 {
                countdownSeconds -= 1
                if isVolumeOn && countdownSeconds <= 3 {
                    beep()
                }
            } else {
                isCountingDown = false
                isWorkingOut = true
            }
        } else if isWorkingOut {
            if onSeconds > 0 {
                onSeconds -= 1
                if isVolumeOn && onSeconds <= 3 {
                    beep()
                }
            } else {
                isWorkingOut = false
                if reps > 0 {
                    reps -= 1
                    isResting = true
                } else {
                    isWorkoutComplete = true
                }
            }
        } else if isResting {
            if offSeconds > 0 {
                offSeconds -= 1
                if isVolumeOn && offSeconds <= 3 {
                    beep()
                } else {
                    isResting = false
                    if reps > 0 {
                        isWorkingOut = true
                    } else {
                        isWorkoutComplete = true
                    }
                }
            } else if isWorkoutComplete {
                resetWorkout()
            }
        }
        
         func resetWorkout() {
            isWorkoutComplete = false
        }
        
         func beep() {
            let systemSoundID: SystemSoundID = 1052
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }
}

//
//  Hittime_Single_FileApp.swift
//  Hittime_Single_File
//
//  Created by Austin Danson on 5/20/23.
//

import SwiftUI

@main
struct Hittime_Single_FileApp: App {
    var body: some Scene {
        WindowGroup {
            // NavigationView is needed to enable the navigation between views.
            NavigationView {
                WorkoutDurationView()
            }
        }
    }
}

