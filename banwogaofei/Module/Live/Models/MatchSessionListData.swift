//
//  MatchSessionListData.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/11.
//

// 每场比赛的场次列表
import Foundation

nonisolated struct MatchSessionData: Codable,Sendable {
    let list: [SessionItem] // 列表
}

struct SessionItem: Identifiable, Codable, Sendable{
    var id: String { key } // 这一行告诉系统：用 key 作为我的唯一身份标识
    
    let key: String // 右侧场次Key
    
    let awayInstitutionName: String // 客场机构名称
    let awayScore: Int // 客场球队得分
    let awayTeamAvatar: String // 客场球队头像
    let awayTeamColorHex: String // 客场球队颜色代码
    let awayTeamColorId: Int // 客场球队颜色ID
    let awayTeamName: String // 客场球队名称
    let goodsKey: String // 左侧赛程Key
    let homeInstitutionName: String // 主场机构名称
    let homeScore: Int // 主场球队得分
    let homeTeamAvatar: String // 主场球队头像
    let homeTeamColorHex: String // 主场球队颜色代码
    let homeTeamColorId: Int // 主场球队颜色ID
    let homeTeamName: String // 主场球队名称
   
    let name: String // 场次名称
    let periods: Int // 场次节数
    
    
}
