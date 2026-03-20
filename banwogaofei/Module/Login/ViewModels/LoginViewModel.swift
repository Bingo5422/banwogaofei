import Foundation
import Combine
import UIKit

class LoginViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var isPhoneNumberValid: Bool = false
    @Published var verificationCode = ""
    @Published var isLoginButtonDisabled = true
    @Published var countdown = 0
    @Published var canSendCode = true
    @Published var isCheckingCoach = false
    @Published var coachCheckError: String?

    var router: Router?
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?

    init() {
        Publishers.CombineLatest($phoneNumber, $verificationCode)
            .map { phone, code in
                // 只有当手机号不等于 11 位，或者验证码为空时，才禁用按钮 (返回 true)
                return !(phone.count == 11 && !code.isEmpty)
            }
            .assign(to: \.isLoginButtonDisabled, on: self)
            .store(in: &cancellables)
        
        // 监听手机号变化，实时重置错误提示
        $phoneNumber
            .sink { [weak self] _ in
                if self?.coachCheckError != nil {
                    self?.coachCheckError = nil
                }
            }
            .store(in: &cancellables)
        
        // 新增：监听微信登录成功拿到 code 的通知
        NotificationCenter.default.publisher(for: NSNotification.Name("WeChatLoginSuccess"))
            .compactMap { $0.object as? String } // 提取通知里的 code 字符串
            .sink { [weak self] code in
                // 拿到 code 后，发起后端登录请求
                self?.performWeChatLogin(with: code)
            }
            .store(in: &cancellables)
    
    }

    func validatePhoneNumber() {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        isPhoneNumberValid = predicate.evaluate(with: phoneNumber)
    }
    
    
    
    //发送验证码
    func sendVerificationCode() {
        coachCheckError = nil
        validatePhoneNumber()
        
        guard isPhoneNumberValid else {
            coachCheckError = "请输入正确的11位手机号"
            return
        }
        
        isCheckingCoach = true
        
        Task {
            do {
                // 1. 调用发送接口
                try await LoginService.shared.sendSmsCodeService(phone: phoneNumber)
                
                // 2. 成功逻辑：说明是教练且验证码已发
                await MainActor.run {
                    self.isCheckingCoach = false
                    self.startCountdown()
                    print("DEBUG: 身份预检通过，验证码发送成功")
                }
                
            } catch {
                // 3. 失败逻辑：在这里处理 1000 错误码
                await MainActor.run {
                    self.isCheckingCoach = false
                    
                    if let netError = error as? NetworkError {
                        switch netError {
                        case .serverError(let code, let msg):
                            if code == 1000 {
                                // 专门针对非教练身份的拦截
                                self.coachCheckError = "该手机号非注册教练"
                            } else {
                                // 其他服务器错误（如验证码发送频繁等）
                                self.coachCheckError = msg
                            }
                        default:
                            self.coachCheckError = netError.errorDescription
                        }
                    } else {
                        self.coachCheckError = "网络连接异常"
                    }
                    print("DEBUG: 发送验证码失败 - \(self.coachCheckError ?? "")")
                }
            }
        }
    }
    
    
    
    //登录
    func login() {
        // 1. 强行收起键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoginButtonDisabled = true
        coachCheckError = nil
            
            // 开启异步任务
        Task {
            do {
                // 执行异步登录
                let _ = try await LoginService.shared.verifyAndLoginService(phone: phoneNumber, code: verificationCode)
                
                // 登录成功，跳转页面必须在主线程执行
                await MainActor.run {
                    if let router = self.router {
                        print("DEBUG: 登录成功，执行跳转到首页")
                        router.navigateTo(.home)
                    } else {
                        print("DEBUG: 登录成功，但 Router 为 nil，无法跳转")
                        self.isLoginButtonDisabled = false // 允许重试
                        self.coachCheckError = "系统错误：未找到导航控制器"
                    }
                }
            } catch {
                // 登录失败处理
                await MainActor.run {
                    print("DEBUG: 登录失败 - \(error.localizedDescription)")
                    self.isLoginButtonDisabled = false
                    self.coachCheckError = (error as? NetworkError)?.errorDescription ?? "登录失败"
                }
            }
        }
            
    }
    
    // 新增：拿着 code 去请求后端接口并处理跳转
    private func performWeChatLogin(with code: String) {
            coachCheckError = nil
        // 微信登录时通常不需要用户交互禁用按钮，但为了保险可以加 loading 状态
        
        Task {
            do {
                print("DEBUG: 开始调用微信登录接口...")
                // Service 层会处理 Persistence (UserManager.shared.saveUser)
                let _ = try await LoginService.shared.wechatLoginService(code: code)
                
                await MainActor.run {
                    print("DEBUG: 微信接口调用成功，准备跳转")
                    self.navigateToHome()
                }
            } catch {
                await MainActor.run {
                    print("DEBUG: 微信登录接口失败 - \(error)")
                    self.handleError(error)
                }
            }
            
        }
    }
        
    
   
    
    
    private func startCountdown() {
        canSendCode = false
        countdown = 60
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                self.stopCountdown()
            }
        }
    }
    
    private func stopCountdown() {
        timer?.cancel()
        timer = nil
        canSendCode = true
        countdown = 0
    }
    
    // MARK: - 唤起微信客户端
    func loginWithWeChat() {
        // 先清除之前的错误提示
        coachCheckError = nil
        
        // 1. 检查手机是否安装了微信
        if WXApi.isWXAppInstalled() {
            let req = SendAuthReq()
            req.scope = "snsapi_userinfo"
            req.state = "banwogaofei_login_state" // 用于防范 CSRF 攻击的随机字符串
            
            // 2. 发起拉起微信的请求
            WXApi.send(req) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.coachCheckError = "唤起微信失败，请重试"
                    }
                }
            }
        } else {
            self.coachCheckError = "请先安装微信客户端"
        }
    }
    private func navigateToHome() {
            guard let router = self.router else {
                print("DEBUG: 💥 严重错误：Router 未注入，无法跳转！")
                self.coachCheckError = "系统错误：未找到导航控制器"
                self.isLoginButtonDisabled = false
                return
            }
            print("DEBUG: 登录成功，执行跳转到首页")
            router.navigateTo(.home)
        }
        
    private func handleError(_ error: Error) {
            // 这里假设 NetworkError 是在项目中定义的
            // 如果项目中没有 NetworkError，请简化为 self.coachCheckError = error.localizedDescription
            
            // 简单的错误映射示例
            self.coachCheckError = error.localizedDescription
            print("DEBUG: 操作失败 - \(self.coachCheckError ?? "")")
    }
    
    deinit {
        timer?.cancel()
        cancellables.removeAll()
    }
}
