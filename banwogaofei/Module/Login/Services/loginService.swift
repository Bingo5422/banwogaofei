
/*
 接管所有的 NetworkManager 调用，并在拿到数据后，
 处理一些“通用副作用”（比如存 Token、存用户信息），然后再把纯净的结果交还给 ViewModel
 */
import Foundation

class LoginService {
    // 单例模式，方便全局调用
    static let shared = LoginService()
    private init() {}


    
    // 发送短信验证码 (异步版)
    func sendSmsCodeService(phone: String) async throws {
        // 直接 await 结果，不需要闭包
        try await NetworkManager.shared.request(LoginApi.sendSmsCodeApi(phone: phone))
    }
    
  
    
    // 验证并登录 (异步版)
    func verifyAndLoginService(phone: String, code: String) async throws -> CoachInfo {
        
        // 1. 调用异步网络请求
        let apiResponse = try await NetworkManager.shared.request(
            LoginApi.verifySmsCodeApi(phone: phone, code: code),
            modelType: LoginData.self//这行代码告诉 NetworkManager：“我这次请求最终想要得到的是一个 LoginData 类型的业务模型，请你帮我处理好网络请求和数据解析。”
        )
        
        // 2. NetworkManager 已确保 code == 0 且 data 存在，这里直接使用
        let usr = apiResponse.info
        print("DEBUG: 登录返回数据: \(usr)")
        // 3.保存 Token 和用户信息
        UserDefaults.standard.set(usr.token, forKey: "login-token")
        UserManager.shared.saveUser(usr)
        print("DEBUG: [loginService] 异步登录成功，数据已持久化")
        return usr
    }
    
   

    // 新增：微信授权登录 (异步版)
    func wechatLoginService(code: String) async throws -> CoachInfo {
        // 1. 调用异步网络请求，传入微信 code
        let apiResponse = try await NetworkManager.shared.request(
            LoginApi.wechatLogin(code: code),
            modelType: LoginData.self
        )
        
        // 2. 解析数据
        let usr = apiResponse.info
        print("DEBUG: 微信登录返回数据: \(usr)")
        
        // 3. 保存 Token 和用户信息 (与手机号登录保持一致)
        UserDefaults.standard.set(usr.token, forKey: "login-token")
        UserManager.shared.saveUser(usr)
        print("DEBUG: [loginService] 微信异步登录成功，数据已持久化")
        
        return usr
    }

        
    
    
    
    
    // 退出登录
    func logout() async throws {
        try await NetworkManager.shared.request(LoginApi.logout)
        UserDefaults.standard.removeObject(forKey: "login-token")
        UserManager.shared.logout()
    }
}
