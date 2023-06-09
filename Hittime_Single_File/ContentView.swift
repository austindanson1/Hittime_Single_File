import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

class NumberOnlyFormatter: Formatter {
    let numberFormatter = NumberFormatter()
    
    override init() {
        super.init()
        numberFormatter.numberStyle = .decimal
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func string(for obj: Any?) -> String? {
        if let intVal = obj as? Int {
            return numberFormatter.string(from: NSNumber(value: intVal))
        }
        return nil
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if let number = numberFormatter.number(from: string) {
            obj?.pointee = number.intValue as AnyObject?
            return true
        }
        return false
    }
    
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789").inverted
        let replacementStringIsLegal = partialString.rangeOfCharacter(from: disallowedCharacterSet) == nil
        return replacementStringIsLegal
    }
}

struct NumberField: View {
    @Binding var value: Int
    var placeholder: String
    let formatter = NumberOnlyFormatter()

    @State private var isUserEditing = false
    @State private var stringValue: String = "0"
    
    var body: some View {
        TextField(placeholder, text: $stringValue)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: UIScreen.main.bounds.width * 0.69)) // Adjust this multiplier as needed
            .onTapGesture {
                if !isUserEditing {
                    isUserEditing = true
                    stringValue = ""
                }
            }
            .onChange(of: stringValue) { newValue in
                if let intValue = Int(newValue) {
                    value = intValue
                }
            }
    }
}



struct NextButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.black) // Change text color to black
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(Color.white) // Change background color to white
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2) // Add border here
            )
    }
}

class WorkoutManager: ObservableObject {
    @Published var workoutDuration: Int = 0
    @Published var restDuration: Int = 0
    @Published var countdown: Int = 0
    @Published var reps: Int = 0
    
    @Published var countdownSecondsRemaining: Int = 0
    @Published var workoutSecondsRemaining: Int = 0
    @Published var restSecondsRemaining: Int = 0
    @Published var repsRemaining: Int = 0
    
    @Published var isCountingDown = true
    @Published var isWorkoutTime = false
    @Published var isRestTime = false
    @Published var isFirstRun = true
    
    @Published var isPaused = false
    @Published var isBeepOn = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var beepPlayer: AVAudioPlayer!

    init() {
        if let beepSound = Bundle.main.url(forResource: "beep", withExtension: "mp3") {
            do {
                beepPlayer = try AVAudioPlayer(contentsOf: beepSound)
                beepPlayer.prepareToPlay()
            } catch {
                print("Couldn't load beep sound")
            }
        }
        
        // Configure the audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    
    func startWorkout() {
        self.countdownSecondsRemaining = countdown
        self.workoutSecondsRemaining = workoutDuration
        self.restSecondsRemaining = restDuration
        self.repsRemaining = reps
    }

    func updateTime() {
        if self.isPaused {
            return
        }

        if self.isFirstRun {
            if self.countdownSecondsRemaining > 0 {
                if countdownSecondsRemaining <= 3 && isBeepOn {
                    playBeep()
                }
                self.countdownSecondsRemaining -= 1
            } else {
                self.isFirstRun = false
                self.isCountingDown = false
                self.isWorkoutTime = true
            }
        } else if self.isWorkoutTime {
            if self.workoutSecondsRemaining > 0 {
                if workoutSecondsRemaining <= 3 && isBeepOn {
                    playBeep()
                }
                self.workoutSecondsRemaining -= 1
            } else {
                self.isWorkoutTime = false
                self.isRestTime = true
                self.restSecondsRemaining = self.restDuration
            }
        } else if self.isRestTime {
            if self.restSecondsRemaining > 0 {
                if restSecondsRemaining <= 3 && isBeepOn {
                    playBeep()
                }
                self.restSecondsRemaining -= 1
            } else {
                self.isRestTime = false
                self.repsRemaining -= 1
                if self.repsRemaining > 0 {
                    self.isWorkoutTime = true
                    self.workoutSecondsRemaining = self.workoutDuration
                }
            }
        }
    }

    func togglePause() {
        self.isPaused.toggle()
    }

    func toggleBeep() {
        self.isBeepOn.toggle()
    }

    func playBeep() {
        if beepPlayer.isPlaying {
            beepPlayer.stop()
            beepPlayer.currentTime = 0
        }
        beepPlayer.play()
        print("Beep sound is playing.") // For debugging purposes
    }

}



struct WorkoutDurationView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationView {
            VStack {
                Text("WORKOUT DURATION")
                    .font(.headline)
                    .foregroundColor(.white)
                NumberField(value: $workoutManager.workoutDuration, placeholder: "")
                NavigationLink(destination: RestDurationView().environmentObject(workoutManager)) {
                    Text("NEXT")
                }
                .buttonStyle(PlainButtonStyle())
                .modifier(NextButtonStyle())
            }.padding()
            .background(Color.black)
        }
    }
}

struct RestDurationView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack {
            Text("REST DURATION")
                .font(.headline)
                .foregroundColor(.white)
            NumberField(value: $workoutManager.restDuration, placeholder: "")
            NavigationLink(destination: CountdownView().environmentObject(workoutManager)) {
                Text("NEXT")
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(NextButtonStyle())
        }.padding()
        .background(Color.black)
    }
}

struct CountdownView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack {
            Text("COUNTDOWN DURATION")
                .font(.headline)
                .foregroundColor(.white)
            NumberField(value: $workoutManager.countdown, placeholder: "")
            NavigationLink(destination: RepetitionsView().environmentObject(workoutManager)) {
                Text("NEXT")
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(NextButtonStyle())
        }.padding()
        .background(Color.black)
    }
}


struct RepetitionsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack {
            Text("REPS")
                .font(.headline)
                .foregroundColor(.white)
            NumberField(value: $workoutManager.reps, placeholder: "")
            NavigationLink(destination: ContentView().environmentObject(workoutManager)) {
                Text("START WORKOUT")
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(NextButtonStyle())
        }.padding()
        .background(Color.black)
    }
}


struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack {
            Spacer()
            if workoutManager.isCountingDown {
                BigNumberView(title: "COUNTDOWN", number: workoutManager.countdownSecondsRemaining)
            } else if workoutManager.isWorkoutTime {
                BigNumberView(title: "WORKOUT", number: workoutManager.workoutSecondsRemaining)
            } else if workoutManager.isRestTime {
                BigNumberView(title: "REST", number: workoutManager.restSecondsRemaining)
            } else {
                BigNumberView(title: "Workout Complete!", number: workoutManager.restSecondsRemaining)
            }
            Spacer()
            RepsNumberView(title: "REPS", number: workoutManager.repsRemaining)
                .padding(.bottom, 20)
            HStack {
                Toggle(isOn: $workoutManager.isBeepOn) {
                    Text("Beep")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
            .padding(.horizontal)
            Button(action: {
                workoutManager.togglePause()
            }) {
                Text(workoutManager.isPaused ? "Resume" : "Pause")
                    .modifier(NextButtonStyle())
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            workoutManager.startWorkout()
        }
        .onReceive(workoutManager.timer) { _ in
            workoutManager.updateTime()
        }
        .background(Color.black)
    }
}



struct BigNumberView: View {
    var title: String
    var number: Int
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)  // Change here
                .foregroundColor(.white)
            Text("\(number)")
                .font(.system(size: UIScreen.main.bounds.width * 0.6)) // Adjust this multiplier as needed
                .foregroundColor(.white)
        }
    }
}

struct RepsNumberView: View {
    var title: String
    var number: Int
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)  // And here
                .foregroundColor(.white)
            Text("\(number)")
                .font(.system(size: UIScreen.main.bounds.width * 0.4)) // Adjust this multiplier as needed
                .foregroundColor(.white)
        }
    }
}

@main
struct Hittime_Single_FileApp: App {
    var workoutManager = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            WorkoutDurationView().environmentObject(workoutManager)
        }
    }
}
