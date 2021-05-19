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
    @IBOutlet weak var compTilt: UIButton!
    
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var pitchLabel: UILabel!
    
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
        compTilt.isEnabled = true
        prevRoll = 0.0
        prevPitch = 0.0
//        prevTimestamp = 0.0
        stopAccels()
        stopGyros()
        stopComps()
    }
    
    @IBAction func measureAccelTilt(_ sender: Any) {
//        measureTilt = true
        startTiltMeasure(tiltType: "accelerometer_tilt")
        startAccelerometers()
        accelTilt.isEnabled = false
    }

    @IBAction func measureGyroTilt(_ sender: Any) {
//        measureTilt = true
        startTiltMeasure(tiltType: "gyroscope_tilt")
        startGyros()
        gyroTilt.isEnabled = false
    }
    
    @IBAction func measureCompTilt(_ sender: Any) {
//        measureTilt = true
        startTiltMeasure(tiltType: "complimentary_tilt")
        startComps()
        compTilt.isEnabled = false
    }
    
    let motion = CMMotionManager()
    var counter:Double = 0
    let numSamples:Double = 2000
    let dt:Double = 1.0 / 60.0
    let alpha:Double = 0.99
    
    var timer_accel:Timer?
    var accelSum: [Double] = [Double](repeating: 0.0, count: 3)
    var accelSum2: [Double] = [Double](repeating: 0.0, count: 3)
    var accelBias: [Double] = [0.0057570114135742185, -0.0065317611694335935, -0.9995346145629883]
    var accelNoise: [Double] = [1.8159588456095667e-05, 3.023396527802111e-06, 9.253116324492439e-06]
    
    var timer_gyro:Timer?
    var gyroSum: [Double] = [Double](repeating: 0.0, count: 3)
    var gyroSum2: [Double] = [Double](repeating: 0.0, count: 3)
    var gyroBias: [Double] = [0.006122914629653678, 0.005937995244341437, -0.01013290776568465]
    var gyroNoise: [Double] = [2.008710893789675e-06, 1.8565217835566259e-06, 1.7285461378278947e-06]
    
    var timer_comp:Timer?
    
    var tilt: [Double] = [Double](repeating: 0.0, count: 2) // tilt is only roll and pitch
    
    var prevRoll: Double = 0.0
    var prevPitch: Double = 0.0

    var tilt_file_url:URL?
    var tilt_fileHandle:FileHandle?
    
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
                
//                let timestamp = NSDate().timeIntervalSince1970
//                let text = "\(timestamp), \(x), \(y), \(z)\n"
//                print ("\(counter) A: \(text)")
                
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
                        
                        aBias.text = String(format: "Accelerometer Bias:  %.3f, %.3f, %.3f", accelBias[0], accelBias[1], accelBias[2])
                        aNoise.text = String(format: "Accelerometer Noise:  %.3f, %.3f, %.3f", accelNoise[0], accelNoise[1], accelNoise[2])
                        aBias.sizeToFit()
                        aNoise.sizeToFit()
                        
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
                    
                    var roll:Double = atan2(-xn, zn) // -pi to pi
                    roll = -copysign(1.0, roll) * (Double.pi - abs(roll))
                    var pitch:Double = -atan2(-yn, copysign(1.0, zn) * sqrt(xn*xn + zn*zn))
                    pitch = -copysign(1.0, pitch) * (Double.pi - abs(pitch))
                    
                    tilt[0] = roll // roll
                    tilt[1] = pitch // pitch
                    
//                    rollLabel.text = String(format: "%.3f", roll)
//                    pitchLabel.text = String(format: "%.3f", pitch)
//
//                    rollLabel.sizeToFit()
//                    pitchLabel.sizeToFit()
//
//                    print ("Accelerometer Tilt: \(tilt[0]), \(tilt[1])")
                    
                    outputTilt(tiltType: "accelerometer_tilt")
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
                                
//                let timestamp = NSDate().timeIntervalSince1970
//                let text = "\(timestamp), \(x), \(y), \(z)\n"
//                print ("\(counter) G: \(text)")
                
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
                        
                        gBias.text = String(format: "Gyro Bias:  %.3f, %.3f, %.3f", gyroBias[0], gyroBias[1], gyroBias[2])
                        gNoise.text = String(format: "Gyro Noise:  %.3f, %.3f, %.3f", gyroNoise[0], gyroNoise[1], gyroNoise[2])
                        gBias.sizeToFit()
                        gNoise.sizeToFit()

                        gyroSum = [Double](repeating: 0.0, count: 3)
                        gyroSum2 = [Double](repeating: 0.0, count: 3)
                        counter = 0
                        stop((Any).self)
                    }
                } else {
                    let xn = (x - gyroBias[0]) * dt
                    let yn = (y - gyroBias[1]) * dt
//                    let zn = (z - gyroBias[2]) * dt
                    
                    // because of how I defined pitch/roll
                    // pitch corresponds with x-axis, and roll with y-axis
                    prevRoll = prevRoll + yn
                    prevPitch = prevPitch + xn
                    
                    tilt[0] = prevRoll // roll
                    tilt[1] = prevPitch // pitch
                    
//                    rollLabel.text = String(format: "%.3f", prevRoll)
//                    pitchLabel.text = String(format: "%.3f", prevPitch)
//
//                    rollLabel.sizeToFit()
//                    pitchLabel.sizeToFit()
//
//                    print ("Gyroscope Tilt: \(tilt[0]), \(tilt[1])")
                    
                    outputTilt(tiltType: "gyroscope_tilt")

                }
             }
          })

          // Add the timer to the current run loop.
          RunLoop.current.add(self.timer_gyro!, forMode: RunLoop.Mode.default)
       }
    }
    
    // I'm feeling lazy, so I don't want to refactor. boo hoo
    func startComps() {
       if self.motion.isAccelerometerAvailable && motion.isGyroAvailable {
          self.motion.gyroUpdateInterval = 1.0 / 60.0
          self.motion.startGyroUpdates()
        
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0
            self.motion.startAccelerometerUpdates()
                
          // Configure a timer to fetch the accelerometer data.
          self.timer_comp = Timer(fire: Date(), interval: (1.0/60.0),
                 repeats: true, block: { [self] (timer) in
             // Get the gyro data.
            if let gyro_data = self.motion.gyroData,
                let accel_data = self.motion.accelerometerData {
                
                let gx = gyro_data.rotationRate.x
                let gy = gyro_data.rotationRate.y
//                let gz = gyro_data.rotationRate.z
                
                let ax = accel_data.acceleration.x
                let ay = accel_data.acceleration.y
                let az = accel_data.acceleration.z
                                
//                let timestamp = NSDate().timeIntervalSince1970
//                let text = "\(timestamp), \(x), \(y), \(z)\n"
//                print ("\(counter) G: \(text)")
                
                if measureTilt {
                    let gxn = (gx - gyroBias[0]) * dt
                    let gyn = (gy - gyroBias[1]) * dt
//                    let zn = (z - gyroBias[2]) * dt
                    
                    // because of how I defined pitch/roll
                    // pitch corresponds with x-axis, and roll with y-axis
                    prevRoll = prevRoll + gyn
                    prevPitch = prevPitch + gxn
                    
                    let norm:Double = sqrt(ax*ax + ay*ay + az*az)
                    let axn = ax / norm
                    let ayn = ay / norm
                    let azn = az / norm
                    
                    var roll:Double = atan2(-axn, azn) // -pi to pi
                    roll = -copysign(1.0, roll) * (Double.pi - abs(roll))
                    var pitch:Double = -atan2(-ayn, copysign(1.0, azn) * sqrt(axn*axn + azn*azn))
                    pitch = -copysign(1.0, pitch) * (Double.pi - abs(pitch))
                    
                    tilt[0] = alpha * prevRoll + (1.0 - alpha) * roll // roll
                    tilt[1] = alpha * prevPitch + (1.0 - alpha) * pitch // pitch
                    
//                    rollLabel.text = String(format: "%.3f", tilt[0])
//                    pitchLabel.text = String(format: "%.3f", tilt[1])
//
//                    rollLabel.sizeToFit()
//                    pitchLabel.sizeToFit()
//
//                    print ("Complimentary Tilt: \(tilt[0]), \(tilt[1])")
                    
                    outputTilt(tiltType: "complimentary_tilt")
                }
             }
          })

          // Add the timer to the current run loop.
          RunLoop.current.add(self.timer_comp!, forMode: RunLoop.Mode.default)
       }
    }
    
    func stopAccels() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
        
          tilt_fileHandle!.closeFile()
       }
    }
    
    func stopGyros() {
       if self.timer_gyro != nil {
          self.timer_gyro?.invalidate()
          self.timer_gyro = nil

          self.motion.stopGyroUpdates()

          tilt_fileHandle!.closeFile()
       }
    }
    
    func stopComps() {
       if self.timer_comp != nil {
          self.timer_comp?.invalidate()
          self.timer_comp = nil

          self.motion.stopAccelerometerUpdates()
          self.motion.stopGyroUpdates()
        
          tilt_fileHandle!.closeFile()
       }
    }
    
    private func startTiltMeasure(tiltType:String) {
        do {
            // get timestamp in epoch time
            let ts = NSDate().timeIntervalSince1970
            let file = "\(tiltType)_file_\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                tilt_file_url = dir.appendingPathComponent(file)
            }
            
            // write first line of file
            try "ts,roll,pitch\n".write(to: tilt_file_url!, atomically: true, encoding: String.Encoding.utf8)

            tilt_fileHandle = try FileHandle(forWritingTo: tilt_file_url!)
            tilt_fileHandle!.seekToEndOfFile()
            measureTilt = true
        } catch {
            print("Error writing to file \(error)")
        }
    }
    
    private func outputTilt(tiltType:String) {
        rollLabel.text = String(format: "%.3f", tilt[0])
        pitchLabel.text = String(format: "%.3f", tilt[1])
        
        rollLabel.sizeToFit()
        pitchLabel.sizeToFit()
        
        print ("\(tiltType): \(tilt[0]), \(tilt[1])")
        
        let timestamp = NSDate().timeIntervalSince1970
        let text = "\(timestamp), \(tilt[0]), \(tilt[1])\n"
//        print ("A: \(text)")
        
        self.tilt_fileHandle!.write(text.data(using: .utf8)!)
    }
    
}

