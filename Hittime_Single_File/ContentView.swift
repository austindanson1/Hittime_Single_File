import SwiftUI
import Combine

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
    
    var body: some View {
        TextField(placeholder, value: $value, formatter: formatter)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: UIScreen.main.bounds.width * 0.69)) // Adjust this multiplier as needed
    }
}


struct NextButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding(.horizontal, 30)  // Add horizontal padding here
            .padding(.vertical, 10)
            .background(Color.black)
            .cornerRadius(10)
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
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {}
    
    func startWorkout() {
        self.countdownSecondsRemaining = countdown
        self.workoutSecondsRemaining = workoutDuration
        self.restSecondsRemaining = restDuration
        self.repsRemaining = reps
    }

    func updateTime() {
        if self.isFirstRun {
            if self.countdownSecondsRemaining > 0 {
                self.countdownSecondsRemaining -= 1
            } else {
                self.isFirstRun = false
                self.isCountingDown = false
                self.isWorkoutTime = true
            }
        } else if self.isWorkoutTime {
            if self.workoutSecondsRemaining > 0 {
                self.workoutSecondsRemaining -= 1
            } else {
                self.isWorkoutTime = false
                self.isRestTime = true
                self.restSecondsRemaining = self.restDuration
            }
        } else if self.isRestTime {
            if self.restSecondsRemaining > 0 {
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
            if workoutManager.isCountingDown {
                Text("Countdown: \(workoutManager.countdownSecondsRemaining)")
                    .foregroundColor(.white)
            } else if workoutManager.isWorkoutTime {
                Text("Workout: \(workoutManager.workoutSecondsRemaining)")
                    .foregroundColor(.white)
            } else if workoutManager.isRestTime {
                Text("Rest: \(workoutManager.restSecondsRemaining)")
                    .foregroundColor(.white)
            } else {
                Text("Workout Complete!")
                    .foregroundColor(.white)
            }
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

@main
struct Hittime_Single_FileApp: App {
    var workoutManager = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            WorkoutDurationView().environmentObject(workoutManager)
        }
    }
}
