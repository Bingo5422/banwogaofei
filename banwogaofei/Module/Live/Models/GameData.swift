//
//  GameData.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/19.
//

import Foundation

// data 字段模型
nonisolated struct GameData: Codable, Sendable {
    let info: GameInfo
}

struct GameInfo: Codable, Sendable {
    let homeInstitutionName: String
    let homeTeamName: String
    let homeTeamAvatar: String
    let homeTeamColorId: Int
    let homeTeamColorHex: String
    let awayInstitutionName: String
    let awayTeamName: String
    let awayTeamAvatar: String
    let awayTeamColorId: Int
    let awayTeamColorHex: String
    let period: Int
    let status: Int
    let homeScore: Int
    let awayScore: Int
    let goodsName: String
    let initInfo: GameInitInfo
    let recordTypeList: [RecordTypeItem]
    let homeTeamKey: String
    let awayTeamKey: String
    let homeCurrentList: [PlayerCurrentModel]
    let awayCurrentList: [PlayerCurrentModel]
    let isLast: Bool
}

struct GameInitInfo: Codable, Sendable {
    let possession: Int
    let homeScore: Int
    let awayScore: Int
    let duration: Int
    let durationLeft: Int
    let pauseDuration: Int
    let pauseDurationLeft: Int
    let homePausesLeft: Int
    let awayPausesLeft: Int
    let homePauses: Int
    let awayPauses: Int
    let homeFouls: Int
    let awayFouls: Int
}

struct RecordTypeItem: Codable, Sendable {
    let id: Int
    let name: String
}

// 球员当前信息模型
struct PlayerCurrentModel: Codable, Sendable {
    let key: String
    let memberCurrentId: Int?
    let memberCurrentKey: String
    let memberKey: String
    let name: String
    let avatar: String
    let sex: Int
    let birthday: Int64?
    let playerNum: String?
    let isRegistered: Bool
    let status: Int
    let memberInfo: MemberInfoModel?
}

// 球员详细信息模型
struct MemberInfoModel: Codable, Sendable {
    let avatar: String?
    let birthday: Int64?
    let certCount: Int?
    let contestCount: Int?
    let currentLevel: CurrentLevelModel?
    let currentMedalStatus: Int?
    let currentPoint: Int?
    let idCardNo: String?
    let jerseySize: String?
    let key: String?
    let memberCurrentKey: String?
    let memberKey: String?
    let momentCount: Int?
    let name: String?
    let nextStage: NextStageModel?
    let nextStageNum: Int?
    let pendingCommentCount: Int?
    let playerNum: Int?
    let ranking: Int?
    let sex: Int?
    let stageCount: Int?
}

// 当前等级模型
struct CurrentLevelModel: Codable, Sendable {
    let icon: String
    let key: String
    let name: String
    let needPoint: Int
}

// 下一阶段模型
struct NextStageModel: Codable, Sendable {
    let description: String
    let key: String
    let video: String
    let videoId: String
}
