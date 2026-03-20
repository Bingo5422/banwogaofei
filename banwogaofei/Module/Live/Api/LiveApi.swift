//
//  MatchApi.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/10.
//

// 只负责定义“请求配置单”，完全不关心网络怎么发
import Foundation
import Alamofire

enum LiveApi: APIRequest {
    
    case getMatchListApi(institutionKey:String)
    case getSessionListApi(goodsKey: String)
    case getGameInfoApi(contestKey: String, period: Int)

    var path: String {
        switch self {
            //获取指定机构创建的对战赛列表
        case .getMatchListApi: return "/bwgf/user/goods-contest/list-by-institution"
            //获取场次列表
        case .getSessionListApi: return "/bwgf/coach/team-contest/list"
            //获取比赛详情
        case .getGameInfoApi: return "/bwgf/user/team-scheduled/view"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var parameters: Parameters? {
        switch self {
            
        case .getMatchListApi(let institutionKey):
            // 这里传入的是 String 或 Int 类型的 institutionKey
            return ["institutionKey": institutionKey.urlEncoded()]
            
        case .getSessionListApi(let goodsKey):
            // 这里传入的是 String 或 Int 类型的 goodsKey
            return ["goodsKey": goodsKey.urlEncoded()]
            
        case .getGameInfoApi(let contestKey, let period):
            // 这里传入的是 String 类型的 contestKey 和 int period
            return [
                "contestKey": contestKey.urlEncoded(),
                "period": period
            ]
            
        }
        
        
    }
}


// WebSocket 专属的 API 配置
enum LiveWSApi {

    // 参数为 gameId 和 scheduleKey
    case matchRealTimeData(gameId: String, scheduleKey: String)

    var buildURL: URL? {
        // 基础域名 (确保这里没有多余的斜杠)
        let host = NetworkConfig.shared.currentEnv.hostUrl

        switch self {
        case .matchRealTimeData(let gameId, let scheduleKey):
            // 定义一个非常严格的字符集：只允许字母和数字
            // 这样所有的标点符号 (+, /, =) 都会被强制转义
            let strictCharset = CharacterSet.alphanumerics
            
            let encodedId = gameId.addingPercentEncoding(withAllowedCharacters: strictCharset) ?? ""
            let encodedKey = scheduleKey.addingPercentEncoding(withAllowedCharacters: strictCharset) ?? ""
            
            // 组装 URL
            let urlString = "\(host)/\(encodedId)/\(encodedKey)"
            return URL(string: urlString)
        }
    }
}
