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
    @IBOutlet weak var gyroBiasNoise: UIButton!
    @IBOutlet weak var aBias: UILabel!
    @IBOutlet weak var aNoise: UILabel!
    @IBOutlet weak var gBias: UILabel!
    @IBOutlet weak var gNoise: UILabel!
    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var accelTilt: UIButton!
    @IBOutlet weak var gyroTilt: UIButton!
    
    var measureTilt:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func measureAccelBiasNoise(_ sender: Any) {
        measureTilt = false
        startAccelerometers()
        accelBiasNoise.isEnabled = false
    }
    
    @IBAction func measureGyroBiasNoise(_ sender: Any) {
        measureTilt = false
        startGyros()
        gyroBiasNoise.isEnabled = false
    }
    
    @IBAction func stop(_ sender: Any) {
        accelBiasNoise.isEnabled = true
        gyroBiasNoise.isEnabled = true
        accelTilt.isEnabled = true
        gyroTilt.isEnabled = true
        prevRoll = 0.0
        prevPitch = 0.0
//        prevTimestamp = 0.0
        stopAccels()
        stopGyros()
    }
    
    @IBAction func measureAccelTilt(_ sender: Any) {
        measureTilt = true
        startAccelerometers()
        accelTilt.isEnabled = false
    }

    @IBAction func measureGyroTilt(_ sender: Any) {
        measureTilt = true
        startGyros()
        gyroTilt.isEnabled = false
    }
    
    let motion = CMMotionManager()
    var counter:Double = 0
    let numSamples:Double = 200
    
    var timer_accel:Timer?
    var accelSum: [Double] = [Double](repeating: 0.0, count: 3)
    var accelSum2: [Double] = [Double](repeating: 0.0, count: 3)
    var accelBias: [Double] = [Double](repeating: 0.0, count: 3)
    var accelNoise: [Double] = [Double](repeating: 0.0, count: 3)
    
    var timer_gyro:Timer?
    var gyroSum: [Double] = [Double](repeating: 0.0, count: 3)
    var gyroSum2: [Double] = [Double](repeating: 0.0, count: 3)
    var gyroBias: [Double] = [Double](repeating: 0.0, count: 3)
    var gyroNoise: [Double] = [Double](repeating: 0.0, count: 3)
    
    var tilt: [Double] = [Double](repeating: 0.0, count: 2) // tilt is only roll and pitch
    
    var prevRoll: Double = 0.0
    var prevPitch: Double = 0.0
//    var prevTimestamp: Double = 0.0

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
                
                if !measureTilt {
                    if counter < numSamples {
                        counter = counter+1
                        accelSum[0] = accelSum[0] + x
                        accelSum[1] = accelSum[1] + y
                        accelSum[2] = accelSum[2] + z
                        
                        accelSum2[0] = accelSum2[0] + x*x
                        accelSum2[1] = accelSum2[1] + y*y
                        accelSum2[2] = accelSum2[2] + z*z
                    } else {
                        for i in 0...2 {
                            accelBias[i] = accelSum[i] / counter
                            accelNoise[i] = accelSum2[i] / counter - accelBias[i] * accelBias[i]
                        }
                        print ("Accelerometer Bias: \(accelBias[0]), \(accelBias[1]), \(accelBias[2])")
                        print ("Accelerometer Noise: \(accelNoise[0]), \(accelNoise[1]), \(accelNoise[2])")
                        
                        accelSum = [Double](repeating: 0.0, count: 3)
                        accelSum2 = [Double](repeating: 0.0, count: 3)
                        counter = 0
                        stop((Any).self)
                    }
                } else {
                    let norm:Double = sqrt(x*x + y*y + z*z)
                    let xn = x / norm
                    let yn = y / norm
                    let zn = z / norm
                    
                    let roll:Double = -atan2(-xn, zn)
                    let pitch:Double = -atan2(-yn, copysign(1.0, zn) * sqrt(xn*xn + zn*zn))
                    
                    tilt[0] = roll // roll
                    tilt[1] = pitch // pitch
                    
                    print ("Accelerometer Tilt: \(tilt[0]), \(tilt[1])")
                }
             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer_accel!, forMode: RunLoop.Mode.default)
       }
    }
    
    func startGyros() {
       if motion.isGyroAvailable {
          self.motion.gyroUpdateInterval = 1.0 / 60.0
          self.motion.startGyroUpdates()
                
          // Configure a timer to fetch the accelerometer data.
          self.timer_gyro = Timer(fire: Date(), interval: (1.0/60.0),
                 repeats: true, block: { [self] (timer) in
             // Get the gyro data.
             if let data = self.motion.gyroData {
                let x = data.rotationRate.x
                let y = data.rotationRate.y
                let z = data.rotationRate.z
                                
                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z)\n"
                print ("\(counter) G: \(text)")
                
                if !measureTilt {
                    if counter < numSamples {
                        counter = counter+1
                        gyroSum[0] = gyroSum[0] + x
                        gyroSum[1] = gyroSum[1] + y
                        gyroSum[2] = gyroSum[2] + z
                        
                        gyroSum2[0] = gyroSum2[0] + x*x
                        gyroSum2[1] = gyroSum2[1] + y*y
                        gyroSum2[2] = gyroSum2[2] + z*z
                    } else {
                        for i in 0...2 {
                            gyroBias[i] = gyroSum[i] / counter
                            gyroNoise[i] = gyroSum2[i] / counter - gyroBias[i] * gyroBias[i]
                        }
                        print ("Gyro Bias: \(gyroBias[0]), \(gyroBias[1]), \(gyroBias[2])")
                        print ("Gyro Noise: \(gyroNoise[0]), \(gyroNoise[1]), \(gyroNoise[2])")
                        
    //                    aBias.text = "\(accelBias[0]), \(accelBias[1]), \(accelBias[2])"

                        gyroSum = [Double](repeating: 0.0, count: 3)
                        gyroSum2 = [Double](repeating: 0.0, count: 3)
                        counter = 0
                        stop((Any).self)
                    }
                } else {
                    let dt:Double = 1.0 / 60.0
                    print("dt: \(dt)")

                    let xn = (x - gyroBias[0]) * dt
//                    let yn = y - gyroBias[1]
                    let zn = (z - gyroBias[2]) * dt
                    
                    prevRoll = prevRoll + xn
                    prevPitch = prevPitch + zn
                    
                    tilt[0] = prevRoll // roll
                    tilt[1] = prevPitch // pitch
                    
                    print ("Gyroscope Tilt: \(tilt[0]), \(tilt[1])")
                }
             }
          })

          // Add the timer to the current run loop.
          RunLoop.current.add(self.timer_gyro!, forMode: RunLoop.Mode.default)
       }
    }
    
    func stopAccels() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
       }
    }
    
    func stopGyros() {
       if self.timer_gyro != nil {
          self.timer_gyro?.invalidate()
          self.timer_gyro = nil

          self.motion.stopGyroUpdates()

//           gyro_fileHandle!.closeFile()
       }
    }
    
}

