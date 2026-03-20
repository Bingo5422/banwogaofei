import Foundation
import Combine
import SwiftUI


@MainActor
class LiveViewModel: ObservableObject {
    @Published var matches: [MatchInfo] = []           // 左侧赛程组列表数据源
    @Published var isLoading = false                    // 左侧赛程列表是否正在加载
    @Published var isShowingMatchList = false          // 是否显示比赛选择半屏弹窗
    @Published var errorMessage: String?               // 错误信息（用于弹窗或文本提示）
    @Published var selectedMatch: MatchInfo?           // 当前选中的左侧赛程对象
    @Published var sessions: [SessionItem] = []        // 右侧具体的场次列表数据源
    @Published var isLoadingSessions = false           // 右侧场次列表是否正在加载
    @Published var isSelectSession = false             // 是否已经完成了最终场次的勾选
    private let liveService = LiveService()
    // 引入 UserManager 单例
    let userManager = UserManager.shared
    
    @Published var currentSession: SessionItem?{// 当前选中的正在直播的场次
       
        didSet {
            guard let session = currentSession else { return }
            // ✅ 1. 每次切换比赛，立即请求该场次的详细信息（包含球员名单）
            Task {
                await getGameInfo(contestKey:session.key, period: session.periods)
            }
                // 只要 currentSession 被赋值（即使是切换），就执行连接逻辑
                setupWebSocketConnection()
            }
    }
    
    private let webSocketService = WebSocketService()
    
    @Published var gameInfo: GameInfo? = nil     //获取某一场比赛的详细信息
    
    
    
    
    // 保存解析后的实时数据
    @Published var realTimeData: RealTimeSessionData? = nil
    
    // 结构化的事件数据，供记分牌监听
    @Published var currentScoreEvent: ScoreEventData? = nil
    @Published var currentTimeoutEvent: TimeoutEventType? = nil
    // ✅ 新增：记录上一帧数据，用于判断暂停次数是否减少
    private var previousInfoData: RealTimeSessionData? = nil
    
    
    
    // 在 LiveViewModel 中增加一个辅助索引
    private var playerCache: [String: PlayerCurrentModel] = [:]

    // 当 getGameInfo 成功获取数据后，立即更新索引
    func updatePlayerCache() {
        guard let info = gameInfo else {
            self.playerCache = [:]
            return
        }
        var newCache: [String: PlayerCurrentModel] = [:]
        for player in info.homeCurrentList + info.awayCurrentList {
            newCache[player.key] = player
        }
        self.playerCache = newCache
    }
    
    
    

    // 请求比赛列表数据
    // 该方法会从 UserManager 获取当前用户的 institutionKey 并请求对应的比赛列表。
    func getMatchList() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 1. 守护：确保用户已登录
                guard let currentUser = userManager.currentUser else {
                    self.errorMessage = "用户未登录"
                    self.isLoading = false
                    return
                }

                // 2. 守护：通过链式调用获取 institutionKey
                // 使用 guard let，解包出来的 institutionKey 在接下来的作用域内一直有效
                guard let institutionKey = currentUser.currentInstitutionInfo?.key else {
                    self.errorMessage = "无法获取机构信息"
                    self.isLoading = false
                    return
                }

                // 此时 institutionKey 在这里是可见的，且已经经过了 UrlEncode 处理
                print("成功获取到 InstitutionKey: \(institutionKey)")
                
                // 3. 调用服务
                let fetchedMatches = try await liveService.getMatchListService(institutionKey: institutionKey)
                
                // 4. 更新比赛列表
                self.matches = fetchedMatches
                
            } catch {
                self.errorMessage = (error as? NetworkError)?.errorDescription ?? "获取比赛列表失败"
            }
            self.isLoading = false
        }
    }
    
    
    // 选中右侧的某个比赛
    func getSessionList(match: MatchInfo) {
        // 1. 记录当前选中的赛程
        self.selectedMatch = match
        
        // 2. 清空上一次的场次数据，并显示加载菊花圈
        self.sessions = []
        self.isLoadingSessions = true
        
        // 3. 开启异步任务去请求数据
        Task {
            do {
                // 传入当前选中赛程的 key 作为 goodsKey
                let fetchedSessions = try await liveService.getSessionListService(goodsKey: match.key)
                self.sessions = fetchedSessions
            } catch {
                print("DEBUG: 获取场次列表失败 \(error)")
                // 这里可以根据需求把错误信息赋值给某个变量弹窗提示
            }
            // 4. 请求结束，关闭加载状态
            self.isLoadingSessions = false
        }
    }
    
    // 选中右侧的某场比赛
    func confirmSelection(session: SessionItem) {
        self.currentSession = session   // 这一行会自动触发上面的 didSet
        self.isShowingMatchList = false
    }
   
    private func setupWebSocketConnection() {
        guard let session = currentSession else { return }
        
        self.previousInfoData = nil // 重新连接时清空旧数据
        
        // --- 步骤 1: 配置回调（只定义逻辑，不发起连接） ---
        webSocketService.onMessageReceived = { [weak self] text in
            guard let self = self else { return }
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let decoder = JSONDecoder()
                // 建议全局开启驼峰转换，处理下划线字段
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // 1. 尝试解析最外层，获取 op 类型
                let baseMsg = try decoder.decode(WSBaseMessage.self, from: data)
                
                if baseMsg.op == "game_info" {
                    // 2. 解析常规比分信息
                    let infoWrapper = try decoder.decode(WSGameInfoWrapper.self, from: data)
                    let newData = infoWrapper.data
                    
                    // 切换回主线程更新 UI
                    DispatchQueue.main.async {
                        if newData.gameState == 3 { // 暂停状态
                            if let oldData = self.previousInfoData {
                                if oldData.gameState != 3 { // 状态刚切换
                                    if newData.teamATimeoutLeft < oldData.teamATimeoutLeft {
                                        self.currentTimeoutEvent = .team(isHome: true)
                                    } else if newData.teamBTimeoutLeft < oldData.teamBTimeoutLeft {
                                        self.currentTimeoutEvent = .team(isHome: false)
                                    } else {
                                        self.currentTimeoutEvent = .referee
                                    }
                                }
                            } else {
                                if self.currentTimeoutEvent == nil {
                                    self.currentTimeoutEvent = .referee
                                }
                            }
                        } else {
                            self.currentTimeoutEvent = nil
                        }
                        
                        self.previousInfoData = newData
                        self.realTimeData = newData
                    }
                }
                
                if baseMsg.op == "game_event" {
                    print("我来了！")
                    
                    let eventWrapper = try decoder.decode(WSGameEventWrapper.self, from: data)
                    let event = eventWrapper.data
                    
                    print("收到事件: \(event.op)")
                    print("事件详情:\(event.data)")
                    
                    if event.op.contains("score") {
                        // 1. 获取可能的球员 Key (优先取 msg 里的，再取外层的)
                        let playerKey = event.data?.msg?.memberCurrentKey ?? event.data?.playerNumber
                        // 2. 获取分值
                        let points = event.data?.msg?.value
                        
                        print("当前得分球员: playerKey=\(playerKey), points=\(points)")
                        // ✅ 修复：只有当两者都不为 nil 时，才进行解包并调用函数
                        if let finalPlayerKey = playerKey, let finalPoints = points {
                            print("✅ 准备触发得分弹窗: Key=\(finalPlayerKey), Points=\(finalPoints)")
                            
                            DispatchQueue.main.async {
                                self.handlePlayerScore(playerKey: finalPlayerKey, points: finalPoints)
                            }
                        } else {
                            // 调试用：如果解包失败，打印出具体哪个是空的
                            print("⚠️ 无法解包得分数据: playerKey=\(playerKey ?? "nil"), points=\(points?.description ?? "nil")")
                        }
                    }
                }
            } catch {
                print("❌ WebSocket 数据解析失败: \(error)")
            }
            
        }
        
        // --- 步骤 2: 发起连接（在闭包外面调用） ---
        // 延时 0.1秒是为了确保在某些生命周期切换时，旧连接已彻底断开
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webSocketService.connect(api: .matchRealTimeData(
                gameId: session.key,
                scheduleKey: session.goodsKey
            ))
        }
    }
    
    

    // 请求比赛详情（球员名单等）
    func getGameInfo(contestKey: String, period: Int) async {
        do {
            // 调用你 LiveService 里的方法
            let info = try await liveService.getGameInfoService(contestKey: contestKey, period: period)
            DispatchQueue.main.async {
                self.gameInfo = info // ✅ 保存到本地，供 handlePlayerScore 使用
                self.updatePlayerCache()
                let totalPlayers = info.homeCurrentList.count + info.awayCurrentList.count
                print("✅ 球员数据已更新，共 \(totalPlayers) 人")
            }
        } catch {
            print("❌ 获取比赛详情失败: \(error)")
        }
    }
    
    
    
    
private  func handlePlayerScore(playerKey: String, points: Int) {
        
        
        // 直接从缓存中取，找不到则使用默认值
        let player = playerCache[playerKey]
        
        
        
        let name = player?.name ?? "球员"
        let number = player?.playerNum ?? "--"
        let avatar = player?.avatar
        
      // ✅ 新增逻辑：判断球员属于哪支队伍，提取队伍颜色
        var teamColorHex = "00A0FF" // 默认颜色备用
        if let info = gameInfo, let session = currentSession {
            if info.homeCurrentList.contains(where: { $0.key == playerKey }) {
                teamColorHex = session.homeTeamColorHex
            } else if info.awayCurrentList.contains(where: { $0.key == playerKey }) {
                teamColorHex = session.awayTeamColorHex
            }
        }
        
        // ✅ 修改点：将 teamColorHex 传给模型
        let newScoreEvent = ScoreEventData(
            avatar: avatar,
            name: name,
            number: number,
            points: points,
            teamColorHex: teamColorHex // 传入刚才解析出的颜色
        )
        
        // 调试日志：确认 key 是否对得上
        print("🏀 收到得分事件: Key=\(playerKey), Points=\(points)")
        print("当前缓存中的 Key: \(playerCache.keys)")

        guard let player = playerCache[playerKey] else {
            print("⚠️ 缓存未命中，无法弹出。")
            return
        }
        
        
        DispatchQueue.main.async {
            // 设置当前事件触发 UI 更新
            self.currentScoreEvent = newScoreEvent
            
            // 3秒后自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // 防覆盖检测：只有当 ID 没变（说明没有新事件覆盖）时才隐藏
                if self.currentScoreEvent?.id == newScoreEvent.id {
                    withAnimation {
                        self.currentScoreEvent = nil
                    }
                }
            }
        }
    }
    
    // MARK: - WebSocket 手动控制
        
    // ✅ 显式断开 WebSocket
    func disconnectWebSocket() {
        webSocketService.disconnect()
        self.previousInfoData = nil
        self.realTimeData = nil
    }
    
    // ✅ 重新连接 WebSocket (用于从后台恢复，或重新开始直播)
    func reconnectWebSocket() {
        // 只有当前有选中的场次才重连
        guard currentSession != nil else { return }
        setupWebSocketConnection()
    }

    
}
