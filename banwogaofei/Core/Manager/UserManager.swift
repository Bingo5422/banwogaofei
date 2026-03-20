import Foundation
import Combine

// 用户管理类：负责当前登录教练信息的持久化存储与内存管理
class UserManager: ObservableObject {
    
    // MARK: - 单例与初始化
    static let shared = UserManager()
    
    private let userDefaultsKey = "saved_coach_info"
    
    // 使用 @Published 确保当 currentUser 改变时，所有引用的 UI 都会自动刷新
    @Published var currentUser: CoachInfo?
    
    private init() {
        // App 启动时，自动从磁盘加载之前保存的用户信息
        loadUser()
    }
    
    // MARK: - 持久化逻辑：存 (Save)
    
    /// 保存用户信息到持久化层 (UserDefaults)
    func saveUser(_ user: CoachInfo) {
        // 1. 编码：将对象转为二进制 JSON 数据
        if let encoded = try? JSONEncoder().encode(user) {
            // 2. 存储：写入磁盘
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            
            // 3. 同步：更新内存中的变量
            // 必须在主线程执行，因为 @Published 会触发 UI 刷新
            DispatchQueue.main.async {
                self.currentUser = user
            }
            print("DEBUG: 用户信息已成功保存到磁盘并同步到内存")
        }
    }
    
    // MARK: - 持久化逻辑：取 (Load)
    
    /// 从持久化层加载用户信息
    private func loadUser() {
        // 1. 读取：从磁盘获取二进制数据
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("DEBUG: 磁盘中未发现已保存的用户信息")
            return
        }
        
        // 2. 解码：将 JSON 数据还原为 CoachInfo 结构体
        if let decodedUser = try? JSONDecoder().decode(CoachInfo.self, from: data) {
            self.currentUser = decodedUser
            print("DEBUG: 已成功从磁盘恢复用户: \(decodedUser.name)")
            if let token = UserDefaults.standard.string(forKey: "login-token") {
                print("用户当前token：\(token)")
            } else {
                print("用户当前token：未找到")
            }
            
           
        }
    }
    
    // MARK: - 退出登录 (Clear)
    
    /// 清除用户信息（退出登录时调用）
    func logout() {
        // 1. 删除磁盘数据
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "login-token") // 同时清除 token
        
        // 2. 清空内存数据
        DispatchQueue.main.async {
            self.currentUser = nil
        }
        print("DEBUG: 用户已登出，持久化数据已清除")
    }
    
    // MARK: - 辅助属性
    
    /// 判断当前是否处于登录状态
    var isLoggedIn: Bool {
        return currentUser != nil
    }
}
