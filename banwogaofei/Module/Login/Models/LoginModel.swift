import Foundation

// 顶层数据结构，对应 APIResponse 中的 data 字段
nonisolated struct LoginData: Codable, Sendable {
    // 必须叫 info，因为后端 JSON 键名是 "info"
    let info: CoachInfo
}

struct CoachInfo: Codable, Sendable {
    let key: String
    let name: String
    let birthday: Int64?           
    let coachCurrentKey: String
    let token: String
    let avatar: String?
    let role: Int
    let sex: Int
    let subscribe: Bool
    
    // 对应截图中的 currentInstitutionInfo
    let currentInstitutionInfo: InstitutionInfo?
    
    // 核心修正：phone 在后端是 CharSequence，JSON 中就是字符串
    // 删掉之前的 PhoneInfo 结构体，直接用 String?
    let phone: String?
}

struct InstitutionInfo: Codable, Sendable {
    let key: String
    let name: String
    let logo: String?
    
    // 建议这些字段都给可选值，防止后端在某些场景下返回空
    let memberCapacity: Int?
    let vipExpiryDate: String?
    let vipTierId: Int?
    let watermark: String?

}
