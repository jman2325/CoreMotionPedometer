//
//  ViewController.swift
//  CoreMotionPedometer
//
//  Created by Jacob Bailey on 8/10/17.
//  Copyright © 2017 Jacob Bailey. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    var pedometerData = CMPedometerData()
    var pedometer = CMPedometer()
    let goGreen = UIColor(red: 0, green: 1.0, blue: 0.15, alpha: 1.0)
    let stopRed = UIColor(red: 1.0, green: 0, blue: 0.15, alpha: 1.0)
    var numberOfSteps: Int! = nil {
        didSet{
//            stepsLabel.text = String(format: "%i", numberOfSteps)
            
        }
    }
    var timer = Timer()
    var distance = 0.0
    var pace = 0.0
    var elapsedSeconds = 0.0
    let interval = 0.1
    let motionActivityManager = CMMotionActivityManager()
    var motionActivity = CMMotionActivity()
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var startStopPedometer: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        startStopPedometer.backgroundColor = goGreen
        stepsLabel.text = "Not Available"
    }

    @IBAction func startStopPedometer(_ sender: UIButton) {
        if sender.titleLabel?.text == "Start" {
            statusLabel.text = "Pedometer On"
            sender.setTitle("Stop", for: .normal)
            sender.backgroundColor = stopRed
            if CMPedometer.isStepCountingAvailable(){
                startTimer()
                startMotionActivityManager()
                pedometer.startUpdates(from: Date(), withHandler: { (pedometerData, error) in
                    if let pedometerData = pedometerData {
                        self.pedometerData = pedometerData
//                        self.stepsLabel.text = "\(pedometerData.numberOfSteps)"
                        self.numberOfSteps = Int(truncating: pedometerData.numberOfSteps)
//                        print("\(Date()) -- \(pedometerData.numberOfSteps)")
                    }
                })
            } else {
                print("Step counting is not available")
            }
        } else {
            pedometer.stopUpdates()
            stopTimer()
            motionActivityManager.stopActivityUpdates()
            statusLabel.text = "Pedometer Off"
            sender.backgroundColor = goGreen
            sender.setTitle("Start", for: .normal)
            readActivityData()
        }
    }
    
    func startTimer() {
        print("Started Timer \(Date())")
        if !timer.isValid{
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (timer) in
                self.displayPedometerData()
                self.elapsedSeconds += self.interval
            })
        }
    }
    
    func displayPedometerData() {
        statusLabel.text = activity() + "--" + minutesSeconds(elapsedSeconds)
        if let numberOfSteps = numberOfSteps{
            stepsLabel.text = String(format: "%i", numberOfSteps)
            print("\(Date()) -- \(stepsLabel.text!)")
        }
        if let pedDistance = pedometerData.distance{
            distance = pedDistance as! Double
            distanceLabel.text = String(format:"%6.2", distance)
            print("\(distanceLabel.text!)")
        }
        let minutesPerMile = 1609.34
        if CMPedometer.isPaceAvailable() {
            if pedometerData.averageActivePace != nil {
                pace = pedometerData.averageActivePace as! Double
                print("\(pace)")
//                paceLabel.text = String(format:"%6.2f", minutesSeconds(pace * minutesPerMile))
                paceLabel.text = "\(minutesSeconds(pace * minutesPerMile))"
//                paceLabel.text = "\(minutesSeconds(calculatedPase() * minutesPerMile))"
            } else {
                paceLabel.text = "N/A"
            }
            print("\(paceLabel.text!)")
        } else {
//            paceLabel.text = "Not Supported"
//            print("Not support for pace.")
            paceLabel.text = "\(minutesSeconds(calculatedPase() * minutesPerMile))"
            print("\(paceLabel.text!)")
        }
    }
    
    func stopTimer() {
        timer.invalidate()
        displayPedometerData()
    }
    
    func minutesSeconds(_ seconds: Double) -> String {
        let minutePart = Int(seconds) / 60
        let secondsPart = Int(seconds) % 60
        return String(format: "%02i:%02i", minutePart, secondsPart)
    }
    
    func calculatedPase() -> Double {
        if distance > 0 {
            return elapsedSeconds/distance
        } else {
            return 0
        }
    }
    
    func startMotionActivityManager() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdates(to: OperationQueue.main, withHandler: { (motionActivity) in
                if let motionActivity = motionActivity {
                    self.motionActivity = motionActivity
                }
            })
        }
    }
    func activity(motionActivity: CMMotionActivity) -> String {
        var activityString = "unknown"
        switch motionActivity.confidence {
        case .low: activityString = "Low"
        case .medium: activityString = "Medium"
        case .high: activityString = "High"
        }
        if motionActivity.stationary{activityString += ":Stationary"}
        if motionActivity.walking{activityString += ":Walking"}
        if motionActivity.running{activityString += ":Running"}
        if motionActivity.automotive{activityString += ":Car"}
        if motionActivity.cycling{activityString += ":Bike"}
        if motionActivity.unknown{activityString += ":Unknown"}
        return activityString
    }
    func activity() -> String {
        var activityString = "unknown"
        switch motionActivity.confidence {
        case .low: activityString = "Low"
        case .medium: activityString = "Medium"
        case .high: activityString = "High"
        }
        if motionActivity.stationary{activityString += ":Stationary"}
        if motionActivity.walking{activityString += ":Walking"}
        if motionActivity.running{activityString += ":Running"}
        if motionActivity.automotive{activityString += ":Car"}
        if motionActivity.cycling{activityString += ":Bike"}
        if motionActivity.unknown{activityString += ":Unknown"}
        return activityString
    }
    
    func readActivityData() {
        let now = Date()
        let yesterday = Date(timeIntervalSinceNow: (-3600 * 24))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .long
        motionActivityManager.queryActivityStarting(from: yesterday, to: now, to: OperationQueue.main) { (motionActivities, error) in
            if let motionActivities = motionActivities {
                for motionActivity in motionActivities {
                    let activityString = dateFormatter.string(from: motionActivity.startDate) + "  " + self.activity(motionActivity: motionActivity)
                    print(activityString)
                }
            }
        }
    }
}





































































































