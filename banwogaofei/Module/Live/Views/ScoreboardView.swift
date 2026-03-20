
import SwiftUI

enum gameState {
    case waiting    // 未开始
    case playing    // 进行中（展示比分、时间）
    case timeout    // 暂停（展示暂停倒计时）
    case end        // 结束（展示最终比分）
}

struct ScoreboardView: View {
    let session: SessionItem
    let realTimeData: RealTimeSessionData?
    let matchName: String
    let scoreEvent: ScoreEventData?
    let timeoutEvent: TimeoutEventType?
    
    @State private var steta: gameState = .waiting
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2){
            
            gameEventBar
            
            HStack(spacing: 4) {
                // ================= 1. 主场区域 =================
                // 主队犯规 (带边框)
                ScoreBlock(text: "\(realTimeData?.teamAFouls ?? 0)",
                           prefix: "犯",
                           hex: session.homeTeamColorHex,
                           color: Color(hex: session.homeTeamColorHex),
                           isFoul: true)
                
                // 主队名字 + 头像 (固定宽度 85, 无边框)
                TeamNameAvatarBlock(name: session.homeTeamName,
                                    avatar: session.homeTeamAvatar,
                                    hex: session.homeTeamColorHex,
                                    nameColor: Color(hex: session.homeTeamColorHex))
                
                // 主队得分 (带边框)
                ScoreBlock(
                    text: (realTimeData?.gameState == 0)
                        ? "\(session.homeScore)"
                        : "\(realTimeData?.teamAScore ?? 0)",
                    hex: session.homeTeamColorHex,
                    color: Color(hex: session.homeTeamColorHex)
                )
                
            
                
                // ================= 2. 中间冒号 =================
                VStack(spacing: 5) {
                    Circle().fill(.white).frame(width: 4, height: 4)
                    Circle().fill(.white).frame(width: 4, height: 4)
                }
                .padding(.horizontal, 2)
                
                // ================= 3. 客场区域 =================
                // 客队得分 (带边框)
                ScoreBlock(
                    text: (realTimeData?.gameState == 0)
                        ? "\(session.awayScore)"
                        : "\(realTimeData?.teamBScore ?? 0)",
                    hex: session.awayTeamColorHex,
                    color: Color(hex: session.awayTeamColorHex)
                )
                
            
                
                // 客队头像 + 名字 (固定宽度 85, 无边框)
                TeamNameAvatarBlock(name: session.awayTeamName,
                                    avatar: session.awayTeamAvatar,
                                    hex: session.awayTeamColorHex,
                                    nameColor: Color(hex: session.awayTeamColorHex),
                                    isLeading: true)
                
                // 客队犯规 (带边框)
                ScoreBlock(text: "\(realTimeData?.teamBFouls ?? 0)",
                           prefix: "犯",
                           hex: session.awayTeamColorHex,
                           color: Color(hex: session.awayTeamColorHex),
                           isFoul: true)
                
                // ================= 4. 右侧时间区域 =================
                HStack(spacing: 6) {
                    Text(formatTime(seconds: realTimeData?.gameLeftSecond ?? 0))
                        .font(.custom("DINCond-Black", size: 18))
                    
                    Rectangle().fill(Color.white.opacity(0.5)).frame(width: 1, height: 12)
                    
                    Text("第\(realTimeData?.period ?? 1)节")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .background(Color.black.opacity(0.5))
            }
            
            .background(Color.black.opacity(0.8))
            
            
            
            
            matchNameBar
        }
        // ✅ 新增：强制 VStack 收缩到内部最宽元素（即主记分牌）的真实宽度
        .fixedSize(horizontal: true, vertical: false)
       
    }
    
    private func formatTime(seconds: Double) -> String {
        let totalSeconds = Int(seconds) // 强制转为 Int，舍弃小数部分
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }


    private var matchNameBar: some View {
        Text(matchName)
            .font(.cktKingkong(size: 8))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical,4)
            .background(Color.black.opacity(0.7))
            .cornerRadius(4)
    }
    
    
    @ViewBuilder
    private var gameEventBar: some View {
        if let score = scoreEvent {
            // ================= 1. 得分事件 UI =================
            HStack(spacing: 8) {
                if let avatarUrl = score.avatar, !avatarUrl.isEmpty {
                    AvatarView(url: avatarUrl)
                } else {
                    Circle().fill(Color.gray.opacity(0.5)).frame(width: 20, height: 20)
                }
                
                HStack(spacing: 4) {
                    Text("\(score.number)")
                        .font(.custom("DINCond-Black", size: 13))
                        .foregroundColor(Color(hex: score.teamColorHex)) // ✅ 修改：使用动态队伍颜色
                    
                    Text(score.name)
                        .font(.custom("PingFangSC-Semibold", size: 12))
                        .foregroundColor(Color(hex: score.teamColorHex))
                    
                    Text("+\(score.points)")
                        .font(.custom("DINCond-Black", size: 18))
                        .foregroundColor(Color(hex: score.teamColorHex)) // ✅ 修改：使用动态队伍颜色
                }
            }
            .padding(.horizontal, 4)
            .background(Color.black.opacity(0.75))
            .cornerRadius(4) // 胶囊圆角
            .transition(.move(edge: .top).combined(with: .opacity))
            
        } else if let timeout = timeoutEvent, realTimeData?.gameState == 3 {
            // ================= 2. 暂停事件 UI =================
            HStack(spacing: 6) {
                
                // ✅ 新增：队伍暂停时展示队伍头像
                if case .team(let isHome) = timeout {
                    AvatarView(url: isHome ? session.homeTeamAvatar : session.awayTeamAvatar)
                        .padding(.leading, 4)
                }
                
                // 暂停归属标识
                Text(timeoutTitle(for: timeout))
                    .font(.custom("PingFangSC-Semibold", size: 12))
                    .foregroundColor(.white)
                              .padding(.leading, 4)
                
                Spacer()
                Text("请求暂停")
                    .font(.custom("PingFangSC-Semibold", size: 12))
                    .foregroundColor(.white)
                    .padding(.leading, 4)
    
                
                // 计时逻辑：裁判暂停为正向计时，队伍暂停为倒计时（剩余）
                let displaySeconds = timeout == .referee
                    ? (realTimeData?.positiveTime ?? 0)
                    : (realTimeData?.timeoutLeftSecond ?? 0)
                
                Text(formatTime(seconds: displaySeconds))
                    .font(.custom("DINCond-Black", size: 16))
                    .foregroundColor(.white) // 醒目的橙色
                    .padding(.trailing, 8)
            }
            // ✅ 宽度严格对齐：同样使用外层 frame 强制宽度并居中
            // ✅ 替换为：
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.75))
            .cornerRadius(4)
            
        }
    }
    // 辅助方法：生成暂停标题文字
    private func timeoutTitle(for timeout: TimeoutEventType) -> String {
        switch timeout {
        case .team(let isHome):
            return isHome ? "\(session.homeTeamName) " : "\(session.awayTeamName) "
        case .referee:
            return "裁判暂停"
        }
    }
}

// MARK: - 子组件：得分/犯规 (保留边框)
struct ScoreBlock: View {
    let text: String
    var prefix: String = ""
    let hex: String
    let color: Color
    var isFoul: Bool = false
    
    var body: some View {
        HStack(spacing: 1) {
            if !prefix.isEmpty {
                Text(prefix).font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.custom("DINCond-Black", size: isFoul ? 16 : 22))
        }
        .foregroundColor(color)
        .frame(width: isFoul ? 30 : 35, height: 30)
        .background(Color(hex: hex).opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: hex), lineWidth: 1.5) // 保留比分和犯规的边框
        )
    }
}

// MARK: - 子组件：固定长度的名字块 (仅背景，无边框)
struct TeamNameAvatarBlock: View {
    let name: String
    let avatar: String
    let hex: String
    let nameColor: Color
    var isLeading: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if isLeading {
                AvatarView(url: avatar)
                Text(name)
                    .font(.custom("PingFangSC-Semibold", size: 12))
                    .lineLimit(1)
                Spacer(minLength: 0) // 名字短时向左对齐
            } else {
                Spacer(minLength: 0) // 名字短时向右对齐
                Text(name)
                    .font(.custom("PingFangSC-Semibold", size: 12))
                    .lineLimit(1)
                AvatarView(url: avatar)
            }
        }
        .foregroundColor(nameColor)
        .padding(.horizontal, 6)
        .frame(width: 120, height: 26) // 固定宽度防止布局跳动
        .background(Color(hex: hex).opacity(0.2)) // 仅背景透明度
        .clipShape(RoundedRectangle(cornerRadius: 4)) // 圆角背景
    }
}

struct AvatarView: View {
    let url: String
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle().fill(Color.gray.opacity(0.3))
        }
        .frame(width: 20, height: 20)
        .clipShape(Circle())
    }
}

struct ViewWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
