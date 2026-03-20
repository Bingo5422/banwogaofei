//
//  APIRequest.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/4.
//

import Foundation
import Alamofire

//协议层

// 定义API请求协议
protocol APIRequest: URLRequestConvertible {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    var headers: HTTPHeaders? { get }
}

extension APIRequest {
    // 默认实现
    var encoding: ParameterEncoding {
        return method == .get ? URLEncoding.default : JSONEncoding.default
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
    
    // 实现 URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        // 获取当前环境的基础URL
        let baseUrlString = NetworkConfig.shared.currentEnv.baseUrl
        guard let baseUrl = URL(string: baseUrlString) else {
            throw AFError.invalidURL(url: baseUrlString)
        }
        
        // 拼接路径
        let url = baseUrl.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        
        // 设置 HTTP 方法
        urlRequest.method = method
        
        // --- 核心修改部分 ---
        // 1. 获取基础公共 Header
        var finalHeaders = NetworkConfig.shared.commonHeaders
        
        // 2. 从本地读取存储的 Token (之前存到了 UserDefaults)
        if let token = UserDefaults.standard.string(forKey: "login-token") {
            // 按照标准的 Bearer 格式注入
            finalHeaders.add(name: "Authorization", value: "Bearer \(token)")
        }
        
        // 3. 加上每个接口特有的 Header
        if let headers = headers {
            headers.forEach { finalHeaders.add($0) }
        }
        urlRequest.headers = finalHeaders
        // --------------------
        
        // 编码参数
        if let parameters = parameters {
            urlRequest = try encoding.encode(urlRequest, with: parameters)
        }
        
        return urlRequest
    }
}
