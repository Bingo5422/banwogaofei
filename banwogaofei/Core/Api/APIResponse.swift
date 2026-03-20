import Foundation

/// 通用后端响应封装
nonisolated struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let code: Int
    let data: T?
    let msg: String
    
    /// 业务逻辑是否成功（约定 0 为成功）
    var isBusinessSuccess: Bool {
        return code == 0
    }
}

/// 空数据占位
nonisolated struct EmptyData: Decodable, Sendable {}
