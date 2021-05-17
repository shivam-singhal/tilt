//
//  ViewController.swift
//  tilt
//
//  Created by stlp on 5/16/21.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var accelBiasNoise: UIButton!
    @IBOutlet weak var aBias: UILabel!
    @IBOutlet weak var aNoise: UILabel!
    @IBOutlet weak var gBias: UILabel!
    @IBOutlet weak var gNoise: UILabel!
    
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func measureAccelBiasNoise(_ sender: Any) {
        startAccelerometers()
        accelBiasNoise.isEnabled = false
    }
    
    //    @IBAction func measureGyroBiasNoise(_ sender: Any) {
//        //startGyros()
//        gyroBiasNoise.isEnabled = false
//    }
    
    @IBAction func stop(_ sender: Any) {
        accelBiasNoise.isEnabled = true
        stopAccels()
    }
    
    let motion = CMMotionManager()
    var counter:Double = 0
    
    var timer_accel:Timer?
    var accelSum: [Double] = [Double](repeating: 0.0, count: 3)
    var accelBias: [Double] = [Double](repeating: 0.0, count: 3)
    var accelNoise: [Double] = [Double](repeating: 0.0, count: 3)
    
//    var timer_gyro:Timer?
//    var gyro_file_url:URL?
//    var gyro_fileHandle:FileHandle?
    
    // TODO: make another timer for complementary filter
    
    // TODO make file handles for tilt
    
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
        // sampling rate can usually go up to at least 100 hz
        // if you set it beyond hardware capabilities, phone will use max rate
          self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
          self.motion.startAccelerometerUpdates()
        
          // Configure a timer to fetch the data.
          self.timer_accel = Timer(fire: Date(), interval: (1.0/60.0),
                                   repeats: true, block: { [self] (timer) in
             // Get the accelerometer data.
             if let data = self.motion.accelerometerData {
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                
                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z)\n"
                print ("\(counter) A: \(text)")
                
                // TODO keep a running count
                if counter < 200 {
                    counter = counter+1
                    accelSum[0] = accelSum[0] + x
                    accelSum[1] = accelSum[1] + y
                    accelSum[2] = accelSum[2] + z
                } else {
                    for i in 0...2 {
                        accelBias[i] = accelSum[i] / counter
                    }
                    print ("Accelerometer Bias: \(accelBias[0]), \(accelBias[1]), \(accelBias[2])")
                    
                    aBias.text = "\(accelBias[0]), \(accelBias[1]), \(accelBias[2])"
                    // TODO: reset bias/counter?
                    accelSum = [Double](repeating: 0.0, count: 3)
                    counter = 0
                    stop((Any).self)
                }
             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer_accel!, forMode: RunLoop.Mode.default)
       }
    }
    
    func stopAccels() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
       }
    }
    
//    func stopGyros() {
//       if self.timer_gyro != nil {
//          self.timer_gyro?.invalidate()
//          self.timer_gyro = nil
//
//          self.motion.stopGyroUpdates()
//
////           gyro_fileHandle!.closeFile()
//       }
//    }
    
}

