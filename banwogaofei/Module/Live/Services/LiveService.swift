import Foundation

class LiveService {
    private let networkManager = NetworkManager.shared

    
    //  获取比赛列表）
    func getMatchListService(institutionKey: String) async throws -> [MatchInfo] {
        
        // 1. 告诉 NetworkManager，期望解码的顶层模型是 APIResponse<MatchListData>
        let apiResponse = try await networkManager.request(
            LiveApi.getMatchListApi(institutionKey:institutionKey),
            modelType: MatchListData.self// 直接指定业务模型，而不是外层的 APIResponse
        )
        // 2. NetworkManager 已确保 code == 0 且 data 存在，这里直接使用
        
        let matchData = apiResponse.list
        
        // 3.返回
        return matchData
    }
    
    
    
    //  获取比赛场次列表
    func getSessionListService(goodsKey: String) async throws -> [SessionItem] {
        // 1. 发起网络请求，携带左侧传过来的 goodsKey
        let apiResponse = try await networkManager.request(
            LiveApi.getSessionListApi(goodsKey: goodsKey),
            modelType: MatchSessionData.self
        )
        
        // 2. 提取出列表数据并返回
        return apiResponse.list
    }
    
    
    //获取比赛信息
    func getGameInfoService(contestKey: String, period: Int) async throws -> GameInfo {
        let apiResponse = try await networkManager.request(
            LiveApi.getGameInfoApi(contestKey: contestKey, period: period),
            modelType: GameData.self
        )
        return apiResponse.info
    }
    
    
    
    
}
