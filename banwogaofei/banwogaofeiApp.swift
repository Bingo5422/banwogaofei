import SwiftUI
import TXLiteAVSDK_Professional

// 1. 整合所有 AppDelegate 逻辑
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    // App 启动完毕回调
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 在这里统一执行组件的初始化
        WeChatManager.shared.registerWeChat()
        return true
    }
    
    // 处理 Universal Link 回调 (iOS 13+)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return WeChatManager.shared.handleUniversalLink(userActivity)
    }
    
    // 处理旧版 URL Scheme 回调
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return WeChatManager.shared.handleOpenURL(url)
    }
}

@main
struct banwogaofeiApp: App {
    // 2. 这里只保留一个 AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var router = Router()
    
    init() {


        setupTencentLive()
        _ = UserManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .onAppear {
                    print(NetworkConfig.shared.currentEnv)
            }
            // 1. 处理 Universal Link (微信推荐方式)
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                print("DEBUG: 捕获到 Universal Link")
                _ = WeChatManager.shared.handleUniversalLink(userActivity)
            }
            
            // 2. 处理 URL Scheme (传统方式)
            .onOpenURL { url in
                print("DEBUG: 捕获到 URL Scheme: \(url)")
                _ = WeChatManager.shared.handleOpenURL(url)
            }
        }
    }
    
    private func setupTencentLive() {
        let licenseURL = "https://1259438581.trtcube-license.cn/license/v2/1259438581_1/v_cube.license"
        let licenseKey = "908c059dd2fdfc95337026506061e501"

        
        TXLiveBase.setLicenceURL(licenseURL, key: licenseKey)
        print("腾讯云直播 License 已配置")
    }
}
