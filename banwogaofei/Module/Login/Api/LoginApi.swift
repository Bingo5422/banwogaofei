import Foundation
import Alamofire

enum LoginApi: APIRequest {
    case sendSmsCodeApi(phone: String)
    case verifySmsCodeApi(phone: String, code: String)
    case wechatLogin(code: String) // 1. 新增微信登录 case
    case logout

    var path: String {
        switch self {
        case .sendSmsCodeApi: return "/bwgf/coach/sms-code/send"
        case .verifySmsCodeApi: return "/bwgf/coach/sms-code/verify"
        // 2. 微信登录的接口路径 
        case .wechatLogin: return "/bwgf/coach/auth/open/login"
        case .logout: return "/api/v1/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .wechatLogin:
            // 只有微信登录使用 GET
            return .get
        default:
            // 其他已有的接口（发送验证码、验证登录等）保持 POST 不变
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .sendSmsCodeApi(let phone):
            return ["phone": phone]
        case .verifySmsCodeApi(let phone, let code):
            return ["phone": phone, "code": code]
        // 3. 将微信返回的 code 作为参数传给后端
        case .wechatLogin(let code):
            return ["code": code]
        case .logout:
            return nil
        }
    }
}
