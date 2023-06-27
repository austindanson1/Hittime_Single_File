import SwiftUI
import AVFoundation
import Combine

// Custom Formatter to allow only numbers
class NumberOnlyFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        return obj as? String
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = Int(string) as AnyObject?
        return true
    }

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789").inverted
        let replacementStringIsLegal = partialString.rangeOfCharacter(from: disallowedCharacterSet) == nil
        return replacementStringIsLegal
    }
}

struct NumberField: View {
    @Binding var value: String
    var placeholder: String
    var body: some View {
        TextField(placeholder, value: $value, formatter: NumberOnlyFormatter())
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: UIScreen.main.bounds.width * 0.69)) // Adjust this multiplier as needed
    }
}

struct WorkoutDurationView: View {
    @State private var workoutDuration: String = "0"
    
    var body: some View {
        VStack {
            Text("WORKOUT DURATION")
                .font(.headline)
            NumberField(value: $workoutDuration, placeholder: "")
            NavigationLink(destination: RestDurationView(workoutDuration: Int(workoutDuration) ?? 0)) {
                Text("NEXT")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)  // Add horizontal padding here
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }.padding()
    }
}
struct RestDurationView: View {
    var workoutDuration: Int
    @State private var restDuration: String = "0"
    
    var body: some View {
        VStack {
            Text("REST DURATION")
                .font(.headline)
            NumberField(value: $restDuration, placeholder: "")
            NavigationLink(destination: CountdownView(workoutDuration: workoutDuration, restDuration: Int(restDuration) ?? 0)) {
                Text("NEXT")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)  // Add horizontal padding here
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }.padding()
    }
}

struct CountdownView: View {
    var workoutDuration: Int
    var restDuration: Int
    @State private var countdown: String = "0"
    
    var body: some View {
        VStack {
            Text("COUNTDOWN DURATION")
                .font(.headline)
            NumberField(value: $countdown, placeholder: "")
            NavigationLink(destination: RepetitionsView(workoutDuration: workoutDuration, restDuration: restDuration, countdown: Int(countdown) ?? 0)) {
                Text("NEXT")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)  // Add horizontal padding here
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }.padding()
    }
}

struct RepetitionsView: View {
    var workoutDuration: Int
    var restDuration: Int
    var countdown: Int
    @State private var reps: String = "0"
    
    var body: some View {
        VStack {
            Text("REPS")
                .font(.headline)
            NumberField(value: $reps, placeholder: "")
            NavigationLink(destination: ContentView(onSeconds: workoutDuration, offSeconds: restDuration, countdownSeconds: countdown, reps: Int(reps) ?? 0)) {
                Text("START WORKOUT")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)  // Add horizontal padding here
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }.padding()
    }
}


struct ContentView: View {
    @State var onSeconds: Int
    @State var offSeconds: Int
    @State var countdownSeconds: Int
    @State var reps: Int
    @State var audioPlayer: AVAudioPlayer?

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
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)  // Add horizontal padding here
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { self.isPaused.toggle() }) {
                Text(isPaused ? "Resume" : "Pause")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)  // Add horizontal padding here
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())

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
            self.cancellable = timer
                .sink { _ in
                    self.timerTick()
                }
        }
        .onDisappear {
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
            } else {
                isCountingDown = false
                isWorkingOut = true
                playBeepSound()
            }
        } else if isWorkingOut {
            if onSeconds > 0 {
                onSeconds -= 1
            } else {
                isWorkingOut = false
                if reps > 0 {
                    reps -= 1
                    isResting = true
                    playBeepSound()
                } else {
                    isWorkoutComplete = true
                }
            }
        } else if isResting {
            if offSeconds > 0 {
                offSeconds -= 1
            } else {
                isResting = false
                if reps > 0 {
                    isWorkingOut = true
                    playBeepSound()
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

    func playBeepSound() {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Unable to load sound file.")
        }
    }
    }

    @main
    struct Hittime_Single_FileApp: App {
        var body: some Scene {
            WindowGroup {
                NavigationView {
                    WorkoutDurationView()
                }
            }
        }
    }


