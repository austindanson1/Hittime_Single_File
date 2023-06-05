import SwiftUI
import Combine
import AVFoundation
//need up and down
//need pause
struct ContentView: View {
    @State private var onSeconds = UserDefaults.standard.integer(forKey: "onSeconds")
    @State private var offSeconds = UserDefaults.standard.integer(forKey: "offSeconds")
    @State private var countdownSeconds = UserDefaults.standard.integer(forKey: "countdownSeconds")
    @State private var reps = UserDefaults.standard.integer(forKey: "reps")

    @State private var isVolumeOn = UserDefaults.standard.bool(forKey: "isVolumeOn")
    @State private var isCountingDown = false
    @State private var isWorkingOut = false
    @State private var isResting = false
    @State private var isWorkoutComplete = false
    @State private var isWorkoutAlertShown = false
    @State private var isPaused = false // New state variable for pause feature
    @State private var cancellable: AnyCancellable? // Make it an @State property

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            NumberInputView(value: $onSeconds, label: "Workout Duration", range: 0...300)
            NumberInputView(value: $offSeconds, label: "Rest Duration", range: 0...300)
            NumberInputView(value: $countdownSeconds, label: "Countdown", range: 0...300)
            NumberInputView(value: $reps, label: "Repetitions", range: 0...300)

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
        .font(.largeTitle)
    }

    
    
    
    struct NumberInputView: View {
        @Binding var value: Int
        let label: String
        let range: ClosedRange<Int>
        
        var body: some View {
            HStack {
                Text(label)
                Spacer()
                Text("\(value)")
                    .onTapGesture {
                        self.value = (self.value + 1) % (self.range.upperBound + 1)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            }
        }
    }
    
    private func startWorkout() {
        if onSeconds > 0 && offSeconds > 0 && reps > 0 {
            UserDefaults.standard.set(onSeconds, forKey: "onSeconds")
            UserDefaults.standard.set(offSeconds, forKey: "offSeconds")
            UserDefaults.standard.set(countdownSeconds, forKey: "countdownSeconds")
            UserDefaults.standard.set(reps, forKey: "reps")
            UserDefaults.standard.set(isVolumeOn, forKey: "isVolumeOn")

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
                    offSeconds = UserDefaults.standard.integer(forKey: "offSeconds")
                } else {
                    isWorkoutComplete = true
                }
            }
        } else if isResting {
            if offSeconds > 0 {
                offSeconds -= 1
                if isVolumeOn && offSeconds <= 3 {
                    beep()
                }
            } else {
                isResting = false
                if reps > 0 {
                    isWorkingOut = true
                    onSeconds = UserDefaults.standard.integer(forKey: "onSeconds")
                } else {
                    isWorkoutComplete = true
                }
            }
        } else if isWorkoutComplete {
            resetWorkout()
        }
    }
    
    private func resetWorkout() {
        onSeconds = UserDefaults.standard.integer(forKey: "onSeconds")
        offSeconds = UserDefaults.standard.integer(forKey: "offSeconds")
        countdownSeconds = UserDefaults.standard.integer(forKey: "onSeconds")
        reps = UserDefaults.standard.integer(forKey: "reps")
        isWorkoutComplete = false
    }
    
    private func beep() {
        let systemSoundID: SystemSoundID = 1052
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

