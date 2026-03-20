//
//  UrlEncodeUtil.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/11.
//

import Foundation

// 定义一个协议，代表可以被 URL 编码的类型
protocol UrlEncodable {
    func urlEncoded() -> String
}

// 让 String 遵循该协议
extension String: UrlEncodable {
    func urlEncoded() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

// 如果你的 ID 是 Int 类型，也可以轻松扩展
extension Int: UrlEncodable {
    func urlEncoded() -> String {
        return String(self).urlEncoded()
    }
}

// 甚至让可选类型也支持，防止 nil 崩溃
extension Optional where Wrapped: UrlEncodable {
    func urlEncoded() -> String {
        switch self {
        case .some(let value): return value.urlEncoded()
        case .none: return ""
        }
    }
}
