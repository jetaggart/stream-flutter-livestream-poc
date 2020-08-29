import UIKit
import Flutter
import HaishinKit
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "io.getstream",
                                           binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            let args = call.arguments as? Dictionary<String, String>
            if call.method == "streamScreen" {
                do {
                    try self!.streamScreen(args: args, result: result)
                } catch let error {
                    result(FlutterError.init(code: "IOS_EXCEPTION_streamScreen",
                                             message: error.localizedDescription,
                                             details: nil))
                }
            } else {
                result(FlutterError.init(code: "IOS_EXCEPTION_NO_METHOD_FOUND",
                                         message: "no method found for: " + call.method,
                                         details: nil));
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    private func streamScreen(args: Dictionary<String, String>?, result: FlutterResult) {
        let session = AVAudioSession.sharedInstance()
        do {
            // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
            if #available(iOS 10.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            } else {
                session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [
                    AVAudioSession.CategoryOptions.allowBluetooth,
                    AVAudioSession.CategoryOptions.defaultToSpeaker]
                )
                try session.setMode(.default)
            }
            try session.setActive(true)
        } catch {
            print(error)
        }

        let rtmpConnection = RTMPConnection()
        let rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
             print(error)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: .back)) { error in
             print(error)
        }
//        rtmpStream.attachScreen(ScreenCaptureSession(shared: UIApplication.shared))
//
//
        let hkView = HKView(frame: window!.rootViewController!.view.bounds)
        hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        hkView.attachStream(rtmpStream)
//
        // add ViewController#view
        window!.rootViewController!.view.addSubview(hkView)
        //stream key: 7e100396-0219-fb9a-2560-49896fbbfbac
        
        rtmpConnection.connect("rtmp://global-live.mux.com:5222/app")
        rtmpStream.publish("a5c0f3e5-0e51-27f7-5768-88da68e387f8")
        print("working??")

        result(true)
    }
}
