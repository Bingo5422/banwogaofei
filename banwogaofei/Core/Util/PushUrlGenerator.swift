import Foundation
import CryptoKit

struct PushUrlGenerator {
    // TODO: 替换为真实域名和 Key
    static let pushDomain = "219679.push.tlivecloud.com"
    static let pushKey = "c5f4d23cf2050adaab0fd92da4177f5f"
    
    
    
    /// 生成推流地址
    static func generatePushUrl(streamName: String) -> String {
        // 设置过期时间（当前时间 + 24小时）
        let txTime = String(format: "%08X", Int(Date().timeIntervalSince1970) + 86400)
        
        // 拼接计算 MD5 的字符串: Key + StreamName + txTime
        let input = pushKey + streamName + txTime
        let txSecret = MD5(input)
        
        // 组装最终 URL
        return "rtmp://\(pushDomain)/live/\(streamName)?txSecret=\(txSecret)&txTime=\(txTime)"
    }
    
    private static func MD5(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
