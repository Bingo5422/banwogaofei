//  MatchListData.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/9.
//

import Foundation

//指定机构创建的对战赛列表

nonisolated struct MatchListData: Codable, Sendable {
    let list: [MatchInfo] // 列表
}

struct MatchInfo: Identifiable, Codable, Sendable {
    let address: String? // 地点
    let durationName: String // 单节时长
    let goodsContestStr: String? // 场景值
    let hasPermission: Bool? // 是否有权限
    let id: Int // 商品ID
    let key: String // 商品Key
    let modeName: String // 模式
    let name: String // 商品名称
    let playerCount: Int? // 球员数量
    let startTime: Int64? // 开始时间
    let teamList: [MatchTeam]? // 球队列表
    let unitName: String// 组别
    
    // 增加一个辅助属性，方便UI显示原本想要的 String 格式 (可选)
    var startTimeString: String {
        guard let time = startTime else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm" // 根据需要调整格式
        return formatter.string(from: date)
    }
}

struct MatchTeam: Identifiable, Codable, Sendable {
    let avatar: String // 头像链接
    let colorHex: String // 球队颜色代码
    let id: Int // 球队ID（分享时用到）
    let isCurrent: Bool // 是否是当前教练所在机构的球队
    let isMine: Bool // 是否是当前教练所在的球队
    let key: String // 球队Key
    let name: String // 名称
    let playerCurrentList: [MatchPlayer] // 球员列表
    let qrcode: String // 球队邀请球员小程序码链接
}

struct MatchPlayer: Codable, Sendable {
    let avatar: String? // 头像链接
    let birthday: Int64?// 出生日期
    let isRegistered: Bool // 是否已注册
    let key: String // 当前机构学员Key (等于memberCurrentKey)
    let memberCurrentKey: String // 当前机构学员Key
    let memberInfo: MemberInfo // 成员信息
    let memberKey: String // 成员Key
    let name: String // 姓名
    let playerNum: String // 球员号码
    let sex: Int // 性别
    let status: Int // 学员状态: 0.未录入, 1.潜客, 2.正式学员, 3.历史学员
}

struct MemberInfo: Codable, Sendable {
    let avatar: String // 头像链接
    let birthday: Int64? // 出生日期
    let certCount: Int // 证书数
    let contestCount: Int // 对战赛数
    let currentLevel: MemberLevel // 当前段位信息
    let currentMedalStatus: Int // 当前奖牌状态
    let currentPoint: Int // 当前经验值
    let idCardNo: String // 身份证号
    let jerseySize: String // 球衣尺码
    let key: String // 成员Key (等于memberKey)
    let memberCurrentKey: String // 当前机构学员Key
    let memberKey: String // 成员Key
    let momentCount: Int // 打卡数
    let name: String // 姓名
    let nextStage: MemberStage // 下一关卡信息
    let nextStageNum: Int // 下一关卡序号
    let pendingCommentCount: Int // 待点评数
    let playerNum: Int // 球员号码
    let ranking: Int // 排名
    let sex: Int // 性别
    let stageCount: Int // 过关数
}

struct MemberLevel: Codable, Sendable {
    let icon: String // 段位图标
    let key: String // 段位Key
    let name: String // 段位名称
    let needPoint: Int // 所需经验值
}

struct MemberStage: Codable, Sendable {
    let description: String // 描述
    let key: String // 关卡Key
    let video: String // 视频链接
    let videoId: String // 视频ID
}
