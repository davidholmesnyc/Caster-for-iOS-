// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import WebKit
import Foundation
class ViewController: UIViewController, GCKDeviceScannerListener, GCKDeviceManagerDelegate,
                                        GCKMediaControlChannelDelegate, UIActionSheetDelegate,UIWebViewDelegate,UISearchBarDelegate{
  let kCancelTitle = "Cancel"
  let kDisconnectTitle = "Disconnect"
  var applicationMetadata: GCKApplicationMetadata?
  var selectedDevice: GCKDevice?
  var deviceManager: GCKDeviceManager?
  var mediaInformation: GCKMediaInformation?
  var mediaControlChannel: GCKMediaControlChannel
  var chromecastButton : UIButton
  var deviceScanner: GCKDeviceScanner
  var btnImage : UIImage
  var btnImageSelected : UIImage
  var castURL = ""
  let CASTER_IMAGE = "https://www.davidholmesnyc.com/headshot.png"
  let PUTIO_MOBILE_URL = "http://m.put.io"
  let PUTIO_LOGIN_URL = "http://put.io/m/login?next=%2Fm%2F%3F"
  let PUTIO_SEARCH_URL = "https://put.io/search?query="
  let PUTIO_USERNAME = ""
  let PUTIO_PASSWORD = ""

    
  var kReceiverAppID: String {
    //You can add your own app id here that you get by registering with the
    // Google Cast SDK Developer Console https://cast.google.com/publish
    return kGCKMediaDefaultReceiverApplicationID;
  }
    
    @IBOutlet weak var searchBar: UISearchBar!
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
       var text = searchBar.text
        let url = NSURL (string:PUTIO_SEARCH_URL+text);
        let requestObj = NSURLRequest(URL: url!);
        self.view.endEditing(true);
        myWebView.loadRequest(requestObj)
    }

    
  // Required init.
  required init(coder aDecoder: NSCoder) {
    let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID:
        kGCKMediaDefaultReceiverApplicationID)
    deviceScanner = GCKDeviceScanner(filterCriteria:filterCriteria);
    mediaControlChannel = GCKMediaControlChannel()
    btnImage = UIImage(named: "icon-cast-identified.png")!
    btnImageSelected = UIImage(named:"icon-cast-connected.png")!
    chromecastButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    super.init(coder: aDecoder)
  }

    
    @IBOutlet weak var myWebView: UIWebView!
    
    @IBOutlet weak var choosechromecast: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //navagation
    var nav = self.navigationController?.navigationBar
    nav?.barTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0) /* #ffffff */
    
    //chromecast button
    // Do any additional setup after loading the view, typically from a nib.
    chromecastButton.addTarget(self, action: "chooseDevice:", forControlEvents: .TouchUpInside)
    chromecastButton.frame = CGRectMake(0, 0, btnImage.size.width, btnImage.size.height)
    chromecastButton.setImage(nil, forState:UIControlState.Normal)
    chromecastButton.hidden = true
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: chromecastButton)
    
    
    // gestures
    var swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
    swipeRight.direction = UISwipeGestureRecognizerDirection.Right
    self.view.addGestureRecognizer(swipeRight)
    var swipeDown = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
    swipeDown.direction = UISwipeGestureRecognizerDirection.Down
    self.view.addGestureRecognizer(swipeDown)
    
    // webview
    let url = NSURL (string: PUTIO_MOBILE_URL);
    let requestObj = NSURLRequest(URL: url!);
    myWebView.loadRequest(requestObj)
    myWebView.delegate = self;
    
    // search bar
    searchBar.delegate = self
    self.view.addSubview(myWebView)

    // Initialize device scanner
    deviceScanner.addListener(self)
    deviceScanner.startScan()

    
  }
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
               myWebView.goBack()
            case UISwipeGestureRecognizerDirection.Down:
                println("Swiped down")
            default:
                break
            }
        }
    }
    
    
    @IBOutlet weak var castVideoButton: UIButton!
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let script = "document.body.innerHTML"
        var test = webView.stringByEvaluatingJavaScriptFromString(script)
        let currentURL : NSString = (myWebView.request?.URL!.absoluteString)!
        println(currentURL)
        if(String(currentURL) == PUTIO_LOGIN_URL && PUTIO_PASSWORD != ""){
            var login = "document.getElementsByName('name')[0].value = '" + PUTIO_USERNAME + "';"
            login += "document.getElementsByName('password')[0].value = '" + PUTIO_PASSWORD + "';"
            login += "document.getElementsByTagName('form')[0].submit()"
            var loginToPUTIO = myWebView.stringByEvaluatingJavaScriptFromString(login)
        }
        
        if let returnedString = webView.stringByEvaluatingJavaScriptFromString(script) {
           // println("the result is \(returnedString)")
            
            var string: NSString = returnedString
            if( string.containsString("Watch MP4") || string.containsString("Download mp4")   ){
                
           
                println("YES")
                toggleMenu("on")
                chromecastContainer.tintColor = UIColor.blueColor()
                castVideoButton.tintColor = UIColor.greenColor()
                var script:String = "";
                castURL = ""
                if(string.containsString("Download mp4")){
                     script = "document.getElementsByClassName('movie-download')[0].getElementsByTagName('a')[0].getAttribute('href')"
                }else{
                     script = "document.getElementsByClassName('button')[0].getAttribute('href')"
                    castURL += "https://www.put.io"
                }
                
                castURL += webView.stringByEvaluatingJavaScriptFromString(script)!
                
            }else{
                toggleMenu("off")
                castVideoButton.tintColor = UIColor.redColor()
            }
            
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        
        
    }
    func webViewDidStartLoad(webView: UIWebView) {
        
       UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    func chromecastCheck(){
        if (!isConnected()) {
            let alert = UIAlertController(title: "Not Connected",
                message: "Please connect to Cast device",
                preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil);
            return;
        }
    }
    
    @IBOutlet weak var chromecastContainer: UIView!
    
    @IBOutlet weak var novideoMessage: UILabel!
    func toggleMenu(off_or_on:String){
        /*
        if(off_or_on == "off"){
            chromecastContainer.hidden = true
            novideoMessage.hidden = false
        }else{
            chromecastContainer.hidden = false
            novideoMessage.hidden = true
        }
*/
        
    }
    
    
  func chooseDevice(sender:AnyObject) {
    if (selectedDevice == nil) {
      var sheet : UIActionSheet = UIActionSheet(title: "Connect to Device",
        delegate: self,
        cancelButtonTitle: nil,
        destructiveButtonTitle: nil)

      for device in deviceScanner.devices  {
        sheet.addButtonWithTitle(device.friendlyName)
      }

      // Add the cancel button at the end so that indexes of the titles map to the array index.
      sheet.addButtonWithTitle(kCancelTitle);
      sheet.cancelButtonIndex = sheet.numberOfButtons - 1;

      sheet.showInView(chromecastButton)

    } else {
      updateStatsFromDevice();
      let friendlyName = "Casting to \(selectedDevice!.friendlyName)";

      var sheet : UIActionSheet = UIActionSheet(title: friendlyName, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil);
      var buttonIndex = 0;

      if let info = mediaInformation {
        sheet.addButtonWithTitle(info.metadata.objectForKey(kGCKMetadataKeyTitle) as! String);
        buttonIndex++;
      }

      // Offer disconnect option.
      sheet.addButtonWithTitle(kDisconnectTitle);
      sheet.addButtonWithTitle(kCancelTitle);
      sheet.destructiveButtonIndex = buttonIndex++;
      sheet.cancelButtonIndex = buttonIndex;

      sheet.showInView(chromecastButton);
    }
  }

  func updateStatsFromDevice() {
    if isConnected() && mediaControlChannel.mediaStatus != nil {
      mediaInformation = mediaControlChannel.mediaStatus.mediaInformation
    
        
    }
  }

  func isConnected() -> Bool {
    if let manager = deviceManager {
      return manager.connectionState == GCKConnectionState.Connected
    } else {
      return false
    }
  }

  func connectToDevice() {
    if (selectedDevice == nil) {
      return
    }
    let identifier = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as! String
   
    deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
    deviceManager!.delegate = self
    deviceManager!.connect()
    
    
  }

  func deviceDisconnected() {
    selectedDevice = nil
    deviceManager = nil
  }

  func updateButtonStates() {
    if (deviceScanner.devices.count == 0) {
      //Hide the cast button
      chromecastButton.hidden = true;
    } else {
      //Show cast button
      chromecastButton.setImage(btnImage, forState: UIControlState.Normal);
      chromecastButton.hidden = false;

      if isConnected() {
        //Show cast button in enabled state
        chromecastButton.tintColor = UIColor.blueColor()
      } else {
        //Show cast button in disabled state
        chromecastButton.tintColor = UIColor.grayColor()
      }
    }
    
    
   
    
  }


  //Cast video
  @IBAction func castVideo(sender:AnyObject) {
    println("Cast Video");
    if castVideoButton.tintColor!.isEqual(UIColor.redColor()) {
        let alert = UIAlertController(title: "No video found",
            message: "When this button turns green then you can cast a video.",
            preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil);
        return;
    }
    // Show alert if not connected.
    if (!isConnected()) {
      let alert = UIAlertController(title: "Not Connected",
        message: "Please connect to Cast device",
        preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil);
      return;
    }
    

    
    // Define Media Metadata.
    let metadata = GCKMediaMetadata();
    metadata.setString("Casting Video", forKey: kGCKMetadataKeyTitle);
    metadata.setString("if it doesn't play in 60 seconds then something is wrong with the video",
        forKey:kGCKMetadataKeySubtitle);
    
    let url = NSURL(string:CASTER_IMAGE);
    metadata.addImage(GCKImage(URL: url, width: 480, height: 360))

    println("castURL - "+castURL)
    // Define Media Information.
    let mediaInformation = GCKMediaInformation(
      contentID: castURL,
      streamType: GCKMediaStreamType.None,
      contentType: "video/mp4",
      metadata: metadata,
      streamDuration: 0,
      mediaTracks: [],
      textTrackStyle: nil,
      customData: nil
    );

    // Cast media.
    mediaControlChannel.loadMedia(mediaInformation, autoplay: true);

  }
    @IBAction func pauseVideo(sender: AnyObject) {
        chromecastCheck()
         mediaControlChannel.pause()
        
    }
    @IBAction func play(sender: AnyObject) {
        chromecastCheck()
        if(mediaControlChannel.mediaStatus != nil){
            println(mediaControlChannel.mediaStatus.streamPosition)
             println(mediaControlChannel.mediaStatus.mediaInformation.streamDuration)
        }
        mediaControlChannel.play()
    }
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    
    @IBOutlet weak var timeLeftContainer: UIButton!
    @IBAction func reloadTime(sender: AnyObject) {
        chromecastCheck()
        
        if(mediaControlChannel.mediaStatus != nil){
            
            var current_time = mediaControlChannel.mediaStatus.streamPosition
            var total_time = mediaControlChannel.mediaStatus.mediaInformation.streamDuration
            let c_time = stringFromTimeInterval(current_time)
            let t_time = stringFromTimeInterval(total_time)
            
            var text = (c_time as String) + "/" + (t_time as String)
            timeLeftContainer.setTitle(text, forState: .Normal)
            println(mediaControlChannel.mediaStatus.streamPosition)
            
        }
        
    }
    @IBAction func rewind(sender: AnyObject) {
        
        
        if(mediaControlChannel.mediaStatus != nil){
            println(mediaControlChannel.mediaStatus.streamPosition)
            var current_time = mediaControlChannel.mediaStatus.streamPosition
            var total_time = mediaControlChannel.mediaStatus.mediaInformation.streamDuration
        
            var rewind = current_time - 30
            mediaControlChannel.seekToTimeInterval(rewind)
        }
    }
  
    
    func stringFromTimeInterval(interval:NSTimeInterval) -> NSString {
        
        var ti = NSInteger(interval)
        
        var ms = Int((interval % 1) * 1000)
        
        var seconds = ti % 60
        var minutes = (ti / 60) % 60
        var hours = (ti / 3600)
        
        return NSString(format: "%0.2d:%0.2d",hours,minutes)
    }
  
    func mediaControlChannelDidUpdateStatus(mediaControlChannel: GCKMediaControlChannel!) {
       /*
        if(mediaControlChannel.mediaStatus != nil){
          
            
            var current_time = mediaControlChannel.mediaStatus?.streamPosition
            
            var total_time = mediaControlChannel.mediaStatus?.mediaInformation.streamDuration
            let c_time = stringFromTimeInterval(current_time!)
            let t_time = stringFromTimeInterval(total_time!)
            
            var text = (c_time as String) + "/" + (t_time as String)
            timeLeftContainer.setTitle(text, forState: .Normal)
            
            
            
            println(mediaControlChannel.mediaStatus.streamPosition)
            
        }
*/
    }
    
  func showError(error: NSError) {
    var alert = UIAlertController(title: "Error", message: error.description, preferredStyle: UIAlertControllerStyle.Alert);
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
    self.presentViewController(alert, animated: true, completion: nil)
  }

}


// MARK: GCKDeviceScannerListener
extension ViewController {

  func deviceDidComeOnline(device: GCKDevice!) {
    println("Device found: \(device.friendlyName)");
    updateButtonStates();
  }

  func deviceDidGoOffline(device: GCKDevice!) {
    println("Device went away: \(device.friendlyName)");
    updateButtonStates();
  }

}


// MARK: UIActionSheetDelegate
extension ViewController {
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
      return;
    } else if (selectedDevice == nil) {
      if (buttonIndex < deviceScanner.devices.count) {
        selectedDevice = deviceScanner.devices[buttonIndex] as? GCKDevice;
        println("Selected device: \(selectedDevice!.friendlyName)");
        connectToDevice();
      }
    } else if (actionSheet.buttonTitleAtIndex(buttonIndex) == kDisconnectTitle) {
      // Disconnect button.
      deviceManager!.leaveApplication();
      deviceManager!.disconnect();
      deviceDisconnected();
      updateButtonStates();
    }
  }
    @IBAction func changePageTest(sender: AnyObject) {
        self.performSegueWithIdentifier("ViewController", sender: self)

    }
}


// MARK: GCKDeviceManagerDelegate
extension ViewController {

  func deviceManagerDidConnect(deviceManager: GCKDeviceManager!) {
    println("Connected.");

    updateButtonStates();
    deviceManager.launchApplication(kReceiverAppID);
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didConnectToCastApplication
    applicationMetadata: GCKApplicationMetadata!,
    sessionID: String!,
    launchedApplication: Bool) {
    println("Application has launched.");
    mediaControlChannel.delegate = self;
    deviceManager.addChannel(mediaControlChannel);
    mediaControlChannel.requestStatus();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didFailToConnectToApplicationWithError error: NSError!) {
    println("Received notification that device failed to connect to application.");

    showError(error);
    deviceDisconnected();
    updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didFailToConnectWithError error: NSError!) {
    println("Received notification that device failed to connect.");

    showError(error);
    deviceDisconnected();
    updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didDisconnectWithError error: NSError!) {
    println("Received notification that device disconnected.");

    if (error != nil) {
      showError(error)
    }

    deviceDisconnected();
    updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didReceiveApplicationMetadata metadata: GCKApplicationMetadata!) {
    applicationMetadata = metadata;
  }
}