import SwiftUI
import UIKit

struct TencentCameraPreview: UIViewRepresentable {
    let manager: LivePusherManager
    
    func makeUIView(context: Context) -> UIView {
        // 1. 去掉写死的 frame，直接初始化空 UIView
        let view = UIView()
        view.backgroundColor = .black
        
        // 2. 关键修复：让底层 UIView 的宽高自动跟随 SwiftUI 容器的变化而变化！
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        manager.startLocalPreview(view: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 无需代码
    }
}
