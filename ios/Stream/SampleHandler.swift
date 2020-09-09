import HaishinKit
import ReplayKit
import VideoToolbox

@available(iOS 10.0, *)
open class SampleHandler: RPBroadcastSampleHandler {
    private var rtmpConnection: RTMPConnection?
    private var rtmpStream: RTMPStream?

    deinit {
        rtmpConnection!.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection!.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
    }

    override open func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        /*
         let logger = Logboard.with(HaishinKitIdentifier)
         let socket = SocketAppender()
         socket.connect("192.168.11.15", port: 22222)
         logger.level = .debug
         logger.appender = socket
         */


        rtmpConnection = RTMPConnection()
        rtmpConnection!.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection!.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        rtmpConnection!.connect("rtmp://global-live.mux.com:5222/app/", arguments: nil)
    }

    override open func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            if rtmpConnection!.connected {
                if let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    rtmpStream!.videoSettings = [
                        .width: dimensions.width,
                        .height: dimensions.height ,
                        .profileLevel: kVTProfileLevel_H264_Baseline_4_2
                    ]
                }
                rtmpStream!.appendSampleBuffer(sampleBuffer, withType: .video)
            }
        case .audioApp:
            break
        case .audioMic:
            rtmpStream!.appendSampleBuffer(sampleBuffer, withType: .audio)
        @unknown default:
            break
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        rtmpConnection!.connect("rtmp://global-live.mux.com:5222/app/")
    }

    @objc
    private func rtmpStatusEvent(_ status: Notification) {
        let e = Event.from(status)
        guard
            let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
                return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            rtmpStream!.publish("6875b2f8-c175-5b78-bcbb-4bfc3972bf21")
            break
        default:
            break
        }
    }
}
