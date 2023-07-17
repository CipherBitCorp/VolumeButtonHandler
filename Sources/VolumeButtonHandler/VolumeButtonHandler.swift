// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import MediaPlayer
import AVFoundation
import AVFAudio

public class VolumeButtonHandler: NSObject {
    public typealias VolumeButtonBlock = () -> Void

    var initialVolume: CGFloat = 0.0
    var session: AVAudioSession?
    var volumeView: MPVolumeView?
    
    var appIsActive = false
    var isStarted = false
    var disableSystemVolumeHandler = false
    var isAdjustingInitialVolume = false
    var exactJumpsOnly: Bool = false
    
    var sessionOptions: AVAudioSession.CategoryOptions?
    var sessionCategory: String = ""
    static let sessionVolumeKeyPath = "outputVolume"
    
    static let maxVolume: CGFloat = 0.99999
    static let minVolume: CGFloat = 0.00001
    let sessionContext = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int>.size, alignment: MemoryLayout<Int>.alignment)
    
    public var upBlock: VolumeButtonBlock?
    public var downBlock: VolumeButtonBlock?
    public var currentVolume: Float = 0.0
    
    override public init() {
        appIsActive = true
        sessionCategory = AVAudioSession.Category.playback.rawValue
        sessionOptions = AVAudioSession.CategoryOptions.mixWithOthers

        sessionContext.storeBytes(of: sessionContext, as: UnsafeMutableRawPointer.self)

        volumeView = MPVolumeView(frame: CGRectMake(CGFloat(MAXFLOAT), CGFloat(MAXFLOAT), 0, 0))
        
        UIApplication.shared.windows.first?.addSubview(volumeView!)
        
        volumeView?.isHidden = true
        exactJumpsOnly = false
    }
    
    deinit {
        stopHandler()
        
        let volumeView = volumeView
        DispatchQueue.main.async {
            volumeView?.removeFromSuperview()
        }
        sessionContext.deallocate()
    }
    
    public func startHandler(disableSystemVolumeHandler: Bool) {
        self.setupSession()
        volumeView?.isHidden = false
        self.disableSystemVolumeHandler = disableSystemVolumeHandler
        self.perform(#selector(setupSession), with: nil, afterDelay: 1)
    }

    public func stopHandler() {
        guard isStarted else { return }
        isStarted = false
        volumeView?.isHidden = false
        self.session?.removeObserver(self, forKeyPath: VolumeButtonHandler.sessionVolumeKeyPath)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func setupSession() {
        guard !isStarted else { return }
        isStarted = true
        self.session = AVAudioSession.sharedInstance()
        setInitialVolume()
        do {
            try session?.setCategory(AVAudioSession.Category(rawValue: sessionCategory), options: sessionOptions!)
            try session?.setActive(true)
        } catch {
            print("Error setupSession: \(error)")
        }
        
        session?.addObserver(self, forKeyPath: VolumeButtonHandler.sessionVolumeKeyPath, options: [.old, .new], context: sessionContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruped(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidChangeActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidChangeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        volumeView?.isHidden = !disableSystemVolumeHandler
    }

    func useExactJumpsOnly(enabled: Bool) {
        exactJumpsOnly = enabled
    }
    
    @objc func audioSessionInterruped(notification: NSNotification) {
        guard let interruptionDict = notification.userInfo,
              let interruptionType = interruptionDict[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return
        }
        switch AVAudioSession.InterruptionType(rawValue: interruptionType) {
        case .began:
            debugPrint("Audio Session Interruption case started")
        case .ended:
            print("Audio Session interruption case ended")
            do {
                try self.session?.setActive(true)
            } catch {
                print("Error: \(error)")
            }
        default:
            print("Audio Session Interruption Notification case default")
        }
    }
    
    public func setInitialVolume() {
        guard let session = session else { return }
        initialVolume = CGFloat(session.outputVolume)
        if initialVolume > VolumeButtonHandler.maxVolume {
            initialVolume = VolumeButtonHandler.maxVolume
            isAdjustingInitialVolume = true
            setSystemVolume(initialVolume)
        } else if initialVolume < VolumeButtonHandler.minVolume {
            initialVolume = VolumeButtonHandler.minVolume
            isAdjustingInitialVolume = true
            setSystemVolume(initialVolume)
        }
        currentVolume = Float(initialVolume)
    }
    
    @objc func applicationDidChangeActive(notification: NSNotification) {
        self.appIsActive = notification.name.rawValue == UIApplication.didBecomeActiveNotification.rawValue
        
        if appIsActive, isStarted {
            setInitialVolume()
        }
    }
    
    public static func volumeButtonHandler(upBlock: VolumeButtonBlock?, downBlock: VolumeButtonBlock?) -> VolumeButtonHandler {
        let instance = VolumeButtonHandler()
        instance.upBlock = upBlock
        instance.downBlock = downBlock
        return instance
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == sessionContext {
            guard let change = change,
                  let newVolume = change[.newKey] as? Float,
                  let oldVolume = change[.oldKey] as? Float else {
                return
            }
            
            if !appIsActive {
                // Probably control center, skip blocks
                return
            }
            
            if disableSystemVolumeHandler && newVolume == Float(initialVolume) {
                // Resetting volume, skip blocks
                return
            } else if isAdjustingInitialVolume {
                if newVolume == Float(VolumeButtonHandler.maxVolume) || newVolume == Float(VolumeButtonHandler.minVolume) {
                    // Sometimes when setting initial volume during setup the callback is triggered incorrectly
                    return
                }
                isAdjustingInitialVolume = false
            }
            
            let difference = abs(newVolume - oldVolume)
            
            debugPrint("Old Vol:%f New Vol:%f Difference = %f", oldVolume, newVolume, difference)
            
            if exactJumpsOnly && difference < 0.062 && (newVolume == 1.0 || newVolume == 0.0) {
                debugPrint("Using a non-standard Jump of %f (%f-%f) which is less than the .0625 because a press of the volume button resulted in hitting min or max volume", difference, oldVolume, newVolume)
            } else if exactJumpsOnly && (difference > 0.063 || difference < 0.062) {
                debugPrint("Ignoring non-standard Jump of %f (%f-%f), which is not the .0625 a press of the actually volume button would have resulted in.", difference, oldVolume, newVolume)
                setInitialVolume()
                return
            }
            
            if newVolume > oldVolume {
                upBlock?()
            } else {
                downBlock?()
            }
            currentVolume = newVolume
            
            if !disableSystemVolumeHandler {
                // Don't reset volume if default handling is enabled
                return
            }
            
            // Reset volume
            setSystemVolume(initialVolume)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setSystemVolume(_ volume: CGFloat) {
        let volumeView = MPVolumeView(frame: .zero)
        if let volumeSlider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                volumeSlider.value = Float(volume)
            }
        }
    }

}
