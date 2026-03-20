//
//  NetworkManager.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/4.
//

import Foundation
import Alamofire

//服务层

// 定义网络错误
enum NetworkError: Error {
    case invalidURL
    case serializationError
    case serverError(code: Int, message: String)
    case unauthorized
    case networkConnectionLost(String) // 新增：网络连接问题
    case requestTimedOut(String)       // 新增：请求超时
    case unknown(String)               // 修改：未知错误，但附带原始信息
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .serializationError: return "数据解析失败"
        case .serverError(_, let message): return message
        case .unauthorized: return "未登录或Token失效"
        case .networkConnectionLost(let msg): return msg
        case .requestTimedOut(let msg): return msg
        case .unknown(let msg): return msg
        }
    }
}


class NetworkManager {
    static let shared = NetworkManager()
    private let session: Session
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConfig.shared.timeout
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - 核心底层方法 (不要删除这个)
    // 所有的异步方法最终都调用这个私有的底层方法
    private func performRequest<T: Decodable>(_ target: APIRequest, modelType: T.Type?, completion: @escaping (Result<T, NetworkError>) -> Void) {
        session.request(target).validate().responseDecodable(of: APIResponse<T>.self) { response in
            // 调试信息：打印原始响应数据
           if let data = response.data, let jsonString = String(data: data, encoding: .utf8) {
               print("✅ [原始响应JSON]: \(jsonString)")
           }
            switch response.result {
            case .success(let wrapper):
                if wrapper.code == 0 {
                    if let data = wrapper.data {
                        completion(.success(data))
                    } else if T.self == EmptyData.self {
                        completion(.success(EmptyData() as! T))
                    } else {
                        completion(.failure(.serializationError))
                    }
                } else {
                    // 业务错误（code != 0）
                    completion(.failure(.serverError(code: wrapper.code, message: wrapper.msg)))
                }
            case .failure(let afError):
                // 打印原始错误，用于调试
                print("❌ [底层网络/解析报错]: \(afError.localizedDescription)")
                
            
                // 将 Alamofire 的错误 (AFError) 转换成我们自定义的 NetworkError
                if let underlyingError = afError.underlyingError as? URLError {
                    switch underlyingError.code {
                    case .timedOut:
                        completion(.failure(.requestTimedOut("请求超时，请检查网络")))
                    case .notConnectedToInternet, .networkConnectionLost:
                        completion(.failure(.networkConnectionLost("网络连接丢失，请稍后重试")))
                    default:
                        completion(.failure(.unknown("网络请求失败: \(underlyingError.localizedDescription)")))
                    }
                } else if response.response?.statusCode == 401 {
                    completion(.failure(.unauthorized))
                } else if let statusCode = response.response?.statusCode {
                    completion(.failure(.serverError(code: statusCode, message: "服务器错误 (\(statusCode))")))
                } else {
                    // 其他无法归类的 AFError
                    completion(.failure(.unknown("发生未知错误")))
                }
               
            }
        }
    }

    // MARK: - 异步接口 (给 ViewModel/Service 使用)
    
    // 1. 有返回值的异步请求
    func request<T: Decodable & Sendable>(_ target: APIRequest, modelType: T.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.performRequest(target, modelType: modelType) { result in
                continuation.resume(with: result)
            }
        }
    }

    // 2. 无返回值的异步请求 (解决 Void 不符合 Decodable 的问题)
    func request(_ target: APIRequest) async throws {
        let _: EmptyData = try await withCheckedThrowingContinuation { continuation in
            self.performRequest(target, modelType: EmptyData.self) { result in
                continuation.resume(with: result)
            }
        }
    }
}


