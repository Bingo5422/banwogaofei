import Foundation

// 1. 基础消息类型判定
struct WSBaseMessage: Codable {
    let op: String // 消息类型，如 "game_info" 或 "game_event"
}

// 2. 比赛持续数据包装
struct WSGameInfoWrapper: Codable {
    let op: String // 标识符 "game_info"
    let data: RealTimeSessionData // 核心实时数据
}

// 3. 突发事件数据包装
struct WSGameEventWrapper: Codable {
    let op: String // 标识符 "game_event"
    let data: WSEventInnerData // 事件内部核心数据
}

struct WSEventInnerData: Codable {
    let op: String // 事件具体类型，如 "score_3", "change_game_state", "change_period"
    let data: WSEventDetail? // 具体的事件详情（可选，因为不同事件结构不同）
}


// 4. 核心实时数据模型 (保持你原有的逻辑，补充注释规范)
struct RealTimeSessionData: Codable, Equatable {
    var gameId: String // 比赛ID
    var scheduleKey: String // 赛程场次ID
    var positiveTime: Double // 暂停正计时
    var period: Int // 当前节次
    var gameState: Int // 比赛状态   0: 未知 1: 未开始 2: 进行中 3: 暂停 4: 结束
    var teamAScore: Int // 队伍A得分
    var teamBScore: Int // 队伍B得分
    var gameTimespan: Double // 单节比赛总时长
    var gameLeftSecond: Double // 单节剩余时间
    var timeoutTimespan: Double // 暂停总时长
    var timeoutLeftSecond: Double // 暂停剩余倒计时
    var teamTimeoutCount: Int // 每节暂停次数上限（A队和B队加起来）
    var teamATimeoutLeft: Int // A队剩余暂停次数
    var teamBTimeoutLeft: Int // B队剩余暂停次数
    var teamAFouls: Int // A队犯规次数
    var teamBFouls: Int // B队犯规次数
    var possession: Int // 球权归属
}

// MARK: - 新增：事件数据结构
struct ScoreEventData: Equatable {
    let avatar: String?
    let name: String
    let number: String
    let points: Int
    let id = UUID() // 用于区分不同事件，确保重新计时
    // 新增队伍颜色属性
    var teamColorHex: String
}

enum TimeoutEventType: Equatable {
    case team(isHome: Bool) // true为主队(A队)，false为客队(B队)
    case referee            // 裁判暂停
}

struct WSEventDetail: Codable {
    let team: String?
    let playerNumber: String? // 对应 JSON 的 player_number
    let period: String?       // 对应 JSON 的 "2" (String 类型)
    let msg: WSEventMsg?
    
    enum CodingKeys: String, CodingKey {
        case team, period, msg
        case playerNumber = "player_number"
    }
}

struct WSEventMsg: Codable {
    let value: Int?
    let memberCurrentKey: String? // 其实 msg 里面也有这个 key
    
    enum CodingKeys: String, CodingKey {
        case value
        case memberCurrentKey = "memberCurrentKey"
    }
}
