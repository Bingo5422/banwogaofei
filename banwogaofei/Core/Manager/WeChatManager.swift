import UIKit
import Foundation

class WeChatManager: NSObject, WXApiDelegate {
    
    static let shared = WeChatManager()
    
    // 1. 独立出注册方法
    func registerWeChat() {
        WXApi.registerApp("wxe27d9bf29da699b2", universalLink: "https://www.banwogaofei.com/app/")
        print("微信 SDK 注册请求已发送")
    }

    // 2. 独立出 Universal Link 处理方法
    func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
    }
    
    // 3. 独立出 URL Scheme 处理方法
    func handleOpenURL(_ url: URL) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }

    // MARK: - 微信授权结果回调
    func onResp(_ resp: BaseResp) {
        if let authResp = resp as? SendAuthResp {
            switch resp.errCode {
            case 0:
                if let code = authResp.code {
                    print("DEBUG: 微信授权成功，Code: \(code)")
                    NotificationCenter.default.post(name: NSNotification.Name("WeChatLoginSuccess"), object: code)
                }
            case -2:
                print("DEBUG: 用户取消了微信登录")
            case -4:
                print("DEBUG: 用户拒绝了微信授权")
            default:
                print("DEBUG: 微信授权失败，错误码: \(resp.errCode)")
            }
        }
    }
}
