import Foundation
import SwiftUI
import Combine
import TXLiteAVSDK_Professional

class LivePusherManager: NSObject, ObservableObject, V2TXLivePusherObserver {
    
    var pusher: V2TXLivePusher?
    @Published var isPushing = false
   
    // ✨ 1. 使用纯 Swift 的 Bool 类型替代腾讯云枚举，绝对安全！
    @Published var is1080P: Bool = true
    
    override init() {
        super.init()
        pusher = V2TXLivePusher(liveMode: .RTMP)
        pusher?.setObserver(self)
        
        pusher?.getBeautyManager()?.setBeautyStyle(.nature)
        pusher?.getBeautyManager()?.setBeautyLevel(5)
        
        // 初始化时设置默认的高清参数（对应 is1080P = true）
        let param = V2TXLiveVideoEncoderParam()
        param.videoResolution = .resolution1920x1080
        param.videoResolutionMode = .landscape
        param.videoBitrate = 3000
        param.minVideoBitrate = 1500
        pusher?.setVideoQuality(param)
    }
    
    // --- WebSocket Metadata ---
    func sendMetadataToStream(_ jsonString: String) {
        guard isPushing, let data = jsonString.data(using: .utf8) else { return }
        pusher?.sendSeiMessage(242, data: data)
    }
    
    // --- SDK Callbacks ---
    func onError(_ code: V2TXLiveCode, message: String, extraInfo: [AnyHashable : Any]) {
        print("TXLive Error: [\(code.rawValue)] \(message)")
    }


    // --- Actions ---
    func startLocalPreview(view: UIView) {
        pusher?.setRenderView(view)
        pusher?.setRenderFillMode(.fill)
        pusher?.startCamera(false)
        pusher?.startMicrophone()
    }
    
    func stopLocalPreview() {
        pusher?.stopCamera()
        pusher?.stopMicrophone()
    }
    
    func startPush(url: String) {
        
        let code = pusher?.startPush(url)
        if let resultCode = code, resultCode.rawValue == 0 {
            isPushing = true
            print("推流成功")
        } else {
            let errorCode = code?.rawValue ?? -1
            print("推流失败，错误码：\(errorCode)")
        }
    }
    
    func stopPush() {
        // 1. 记录断开前的摄像头方向（前后置）
        let isFront = pusher?.getDeviceManager()?.isFrontCamera() ?? true
        
        pusher?.stopPush()
        // 2. 清除水印，防止停止后水印变成黑框残留遮挡
        pusher?.setWatermark(nil, x: 0, y: 0, scale: 0)
        isPushing = false
        
        // ✅ 3. 核心修复：强制重新激活本地相机和麦克风，确保预览画面不断
        pusher?.startCamera(isFront)
        pusher?.startMicrophone()
    }
    
    
    @MainActor
    func updateScoreboardWatermark(from view: some View) {
        let controller = UIHostingController(rootView: view.ignoresSafeArea())
        let targetView = controller.view
        targetView?.backgroundColor = .clear
        
        // 1. 强制排版并获取完全展开的真实尺寸（不再写死 500x100）
        targetView?.sizeToFit()
        let targetSize = targetView?.intrinsicContentSize ?? CGSize(width: 500, height: 100)
        
        // 防止尺寸无效导致崩溃
        guard targetSize.width > 0 && targetSize.height > 0 else { return }
        
        targetView?.bounds = CGRect(origin: .zero, size: targetSize)
        
        // 2. 渲染高清截图
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0 // 提升清晰度到 3x
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let image = renderer.image { _ in
            targetView?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }

        // 3. 计算坐标（动态锚定底部）
        let watermarkScale: Float = 0.45 // 水印占据推流画面宽度的比例（可微调）
        let xPos: Float = (1.0 - watermarkScale) / 2.0 // 保持水平居中
        
        // 假设推流配置是 16:9（如 1920x1080）
        let imageRatio = Float(targetSize.height / targetSize.width)
        let videoRatio: Float = 16.0 / 9.0
        let bottomMargin: Float = 0.05 // 距离底部边缘留出 5% 空隙
        
        // 🌟 核心算法：通过计算画面高度占比，让记分牌永远以底部对齐，弹窗向上延伸
        var yPos = 1.0 - bottomMargin - (videoRatio * watermarkScale * imageRatio)
        if yPos < 0 { yPos = 0 }

        pusher?.setWatermark(image, x: xPos, y: yPos, scale: watermarkScale)
    }
    
    func onPushStatusUpdate(_ status: V2TXLivePushStatus, message: String, extraInfo: [AnyHashable : Any]) {
        print("📢 SDK Status: \(status.rawValue), Msg: \(message)")
        
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .disconnected:
                print("TXLive Status: 已断开连接（可能是网络错误或服务器拒绝）")
                self?.isPushing = false
            case .connecting:
                print("TXLive Status: 正在连接...")
            case .connectSuccess:
                print("TXLive Status: 连接成功")
                self?.isPushing = true
            @unknown default:
                break
            }
        }
    }
    
    func setResolution(to1080P: Bool) {
        let param = V2TXLiveVideoEncoderParam()
        param.videoResolutionMode = .landscape
        
        if to1080P {
            param.videoResolution = .resolution1920x1080
            param.videoBitrate = 3000
            param.minVideoBitrate = 1500
        } else {
            param.videoResolution = .resolution1280x720
            param.videoBitrate = 1800
            param.minVideoBitrate = 800
        }
        
        self.pusher?.setVideoQuality(param)
        
        DispatchQueue.main.async {
            self.is1080P = to1080P
        }
    }
    
    
    func onStatisticsUpdate(_ statistics: V2TXLivePusherStatistics) {
        // 这里可以获取实时数据
        print("当前编码宽度: \(statistics.width)")
        print("当前编码高度: \(statistics.height)")
        print("实时码率: \(statistics.videoBitrate)kbps")
    }

    
    deinit {
        stopPush()
        stopLocalPreview()
    }
}

// ✅ 补全: 将 SwiftUI View 转换为 UIImage 的扩展
extension View {
    func snapshot() -> UIImage? {
        // 创建 HostingController
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view
        
        // 计算目标尺寸 (避免 infinite size 问题)
        // 假设水印视图不会超过屏幕大小，给一个合理的 bounds 限制
        let targetSize = controller.view.intrinsicContentSize
        
        // 只有当尺寸有效时才渲染
        if targetSize.width <= 0 || targetSize.height <= 0 { return nil }
        
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        // 渲染图片
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
}
