//
//  BannerView.swift
//  AdView
//
//  Created by Agrahyah on 28/03/22.
//

import UIKit

public class BannerView: UIView {

    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imgView: UIImageView!
    let nibName = "BannerView"
    var contentView: UIView!
    
    public override init(frame: CGRect) {
  
      super.init(frame: frame)
      setUpView()
        PlayerManager.sharedInstance.delegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
      
       super.init(coder: aDecoder)
      setUpView()
    }

    private func setUpView() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        self.contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView
        addSubview(contentView)
        
        contentView.center = self.center
        contentView.autoresizingMask = []
        contentView.translatesAutoresizingMaskIntoConstraints = true
        
        
    }
    
    fileprivate func setPlayPauseButtonImage(_ status: PlayerStatus) {
     
        switch status {
        case .loading, .none: 
            btnPlay.setImage(UIImage(systemName: "play.fill"), for:.normal)
        case .readyToPlay : break
         
        case  .paused:
            btnPlay.setImage(UIImage(systemName: "play.fill"), for:.normal)
        
        case .playing:
            btnPlay.setImage(UIImage(systemName: "pause.fill"), for:.normal)

        case .failed:
          
        break
        }
    }
    
    
    @IBAction func btnPlayClicked(_ sender: Any) {
        if(btnPlay.currentImage == UIImage(systemName: "play.fill")){
            btnPlay.setImage(UIImage(systemName: "pause.fill"), for:.normal)

            PlayerManager.sharedInstance.play()
  
        }else {
            btnPlay.setImage(UIImage(systemName: "play.fill"), for:.normal)
           PlayerManager.sharedInstance.pause()
        }

    }
    
    public func play( Url : String)
    {
            PlayerManager.sharedInstance.setplayer(data: Url) {
            PlayerManager.sharedInstance.play()
        }
        
    }

}

extension BannerView: PlayerDelegate {
   

    func playerManager(_ playerManager: PlayerManager, progressDidUpdate percentage: Double) {
        self.slider.setValue(Float(percentage), animated: true)
       
    }

    func playerManager(_ playerManager: PlayerManager, statusDidChange status: PlayerStatus) {
        print("statusDidChange")

        self.setPlayPauseButtonImage(status)
    }





}
