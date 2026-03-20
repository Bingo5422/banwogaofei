import Alamofire

//配置层

// 环境枚举（保留并补充注释）
enum AppEnv {
    case test // 测试环境（App测试版）
    case prod // 生产环境（App正式版）
    
    // 普通HTTPS接口的baseUrl
    var baseUrl: String {
        switch self {
        case .test: return "https://apptest.banwogaofei.com"
        case .prod: return "https://app.banwogaofei.com"
        }
    }
    
    // WebSocket长连接的hostUrl
    var hostUrl: String {
        switch self {
        case .test: return "wss://websockettest.banwogaofei.com"
        case .prod: return "wss://websocket.banwogaofei.com"
        }
    }
}

// 全局环境配置单例（核心：统一管理环境+网络配置）
class NetworkConfig {
    // 单例（保证全局唯一）
    static let shared = NetworkConfig()
    private init() {}
    
    // 当前环境（默认生产，Debug模式下可切换为测试）
    #if DEBUG
    var currentEnv: AppEnv = .test // 调试模式默认测试环境
    #else
    var currentEnv: AppEnv = .prod // 正式包默认生产环境
    #endif
    
    // 通用配置
    let timeout: TimeInterval = 15 // 请求超时时间
    let commonHeaders: HTTPHeaders = [ // 全局请求头
        "Content-Type": "application/json",
        "Accept": "application/json",
        "App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
        "Device-Type": "iOS"
    ]
    
    // 手动切换环境（调试用，比如在App内加个隐藏入口调用）
    func switchEnv(_ env: AppEnv) {
        currentEnv = env
        // 切换后可清空Token/缓存（可选）
        UserDefaults.standard.removeObject(forKey: "login-token")
    }
}
