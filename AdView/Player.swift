//
//  Player.swift
//  AdView
//
//  Created by Agrahyah on 28/03/22.
//



import Foundation
import AVFoundation
import AVKit
import MediaPlayer



public enum PlayerStatus : Int {
    case none
    case loading
    case failed
    case readyToPlay
    case playing
    case paused
}

protocol PlayerDelegate : AnyObject {
  func playerManager(_ playerManager: PlayerManager, progressDidUpdate percentage: Double)
  
   func playerManager(_ playerManager: PlayerManager, statusDidChange status: PlayerStatus)
   
  
  
}


class PlayerManager : NSObject {
     
    weak var delegate : PlayerDelegate?
    static var sharedInstance = PlayerManager()
    fileprivate var timer: Timer?
    var nowplayingInfo = [String :Any]()
    public var rate: Float = 1.0
    var AudioPlayer: AVPlayer!
    var totalDuration : String = ""
    var currentPlayingTime :String = ""

    fileprivate var status: PlayerStatus = .none {
        didSet {
            self.delegate?.playerManager(self, statusDidChange: status)
        }
    }
    
    public var currentTime: TimeInterval {
        return self.AudioPlayer?.currentItem?.currentTime().seconds ?? 0
    }
    public var duration: TimeInterval {
        return self.AudioPlayer?.currentItem?.asset.duration.seconds ?? 0
    }
   
    
  

    override init() {
        super.init()
    setCommandCenter()
     
    }



    //Playing
    func play(){
        self.status = .playing
       
        AudioPlayer?.play()
        self.updateProgress()
        self.updateNowPlaying()
        if self.timer == nil {
            self.timer = Timer(timeInterval: 1.0, target: self, selector: #selector(self.updateProgress), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer!, forMode: .common)
        }
        
    }

    //Pause
    func pause(){
        self.status = .paused
        AudioPlayer?.pause()
        self.status = .paused
        timer?.invalidate()
        timer = nil
        updateProgress()
      
    }
  
    func stop(){
       
        AudioPlayer?.currentItem?.seek(to: .zero , completionHandler: nil)
        AudioPlayer?.pause()
        self.status = .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        NotificationCenter.default.removeObserver(self)
  
    }
    

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    
    }
   
    func setplayer(data : String, completion: ()->()){
        status = .paused
        AudioPlayer?.pause()
        var url : URL?
        url = URL(string:data)
        guard let url = url else {
            
            return
        }
        
        let playerItem = AVPlayerItem( url:url as URL)
        AudioPlayer = AVPlayer(playerItem:playerItem)
        AudioPlayer.play()
        updateNowPlaying()
        
        
        let keysToObserve = ["currentItem","rate"]
        for key in keysToObserve {
            AudioPlayer?.addObserver(self, forKeyPath: key, options: [.new, .old, .initial], context: nil)
        }
                
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        let selector = #selector(self.playerEndedPlaying(notification:))
        let name = NSNotification.Name.AVPlayerItemDidPlayToEndTime
        
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        AudioPlayer?.actionAtItemEnd = .none
        
        self.play()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        completion()
        
    }
     
    
    @objc func playerEndedPlaying(notification: Notification)   {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

       self.stop()
   
    }
    
    private func stringFromTimeInterval(interval: TimeInterval) -> String {
        if interval.isNaN {
            return ""
        }
        
        let ti = NSInteger(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        if hours > 0 {
            return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
        } else {
            return String(format: "%0.2d:%0.2d",minutes,seconds)
        }
    }
  
    
    
    @objc fileprivate func updateProgress() {
         guard let duration = AudioPlayer?.currentItem?.asset.duration else {
            return
        }
        
        if self.status != .playing, AudioPlayer?.status == .readyToPlay, AudioPlayer?.rate ?? 0 > 0 {
            self.status = .playing
        }
        let currentTime = self.AudioPlayer?.currentTime() ?? .zero
     
        let percentage = currentTime.seconds / duration.seconds
   
        delegate?.playerManager(self, progressDidUpdate: percentage)
    }

    @objc func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            AudioPlayer.rate = 0
            self.pause()
        } else if type == .ended {
            guard let optionsValue =
                    info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                AudioPlayer.rate = 1
                self.play()
                
            }
        }
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {


        switch keyPath {
        case "currentItem":
            self.status = .loading

            AudioPlayer?.currentItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            updateNowPlaying()
            break

        case "status":
            if let item = object as? AVPlayerItem {
                switch (item.status) {
                case .unknown:

                 self.status = .none
                case .readyToPlay:
                    if AudioPlayer?.rate ?? 0 > 0 {
                        self.status = .playing
                    } else {
                        self.status = .readyToPlay
                    }
                case .failed:
                    self.status = .failed
                @unknown default:
                    break
                }
            }
            break
        case "rate":
            if let player = self.AudioPlayer {
                self.status = player.rate > 0 ? .playing : .paused
            } else {
                self.status = .none
            }
            break

        default:
            debugPrint("KeyPath: \(String(describing: keyPath)) not handeled in observer")
        }

    }
    

    
    func updateNowPlaying() {
        nowplayingInfo[MPMediaItemPropertyTitle] = "Ads"
        nowplayingInfo[MPMediaItemPropertyArtist] = ""
        nowplayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  self.AudioPlayer?.currentTime().seconds ?? 0
        nowplayingInfo[MPMediaItemPropertyPlaybackDuration] = self.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowplayingInfo
        
    }

 func setCommandCenter()
    {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowAirPlay, .allowBluetoothA2DP])
         
            try  AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            UIApplication.shared.beginReceivingRemoteControlEvents()
       
        } catch {
            print("Activate AVAudioSession failed.")
        }
        
    
        let commandCenter = MPRemoteCommandCenter.shared();
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { event in
            return .success
            
        }
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [self]event in
            self.status = .playing
            self.play()
            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [self]event in
            self.status = .paused
            self.pause()
            return .success
        }
      
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
    }
}

