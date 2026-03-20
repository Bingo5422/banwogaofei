import SwiftUI

struct MatchSelectionView: View {
    @ObservedObject var viewModel: LiveViewModel

    var body: some View {
        ZStack {
            // 保持原有的 HStack 结构不变
            HStack(spacing: 0) {
                // --- 1. 最左侧：独立的返回按钮区域 (严格保持原样) ---
                VStack {
                    Button(action: {
                        viewModel.isShowingMatchList = false
                    }) {
                        Image("back") // 保持你的原图标
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.leading, 25)  // 保持原间距
                .padding(.top, 12)     // 保持原间距
                .frame(width: 40)

                // --- 2. 内容区域：根据状态切换渲染内容 ---
                if viewModel.isLoading {
                    ProgressView("加载中...").frame(maxWidth: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage).foregroundColor(.red).padding()
                        Button("重试") { viewModel.getMatchList() }
                    }.frame(maxWidth: .infinity)
                } else if viewModel.matches.isEmpty {
                    // ✅ 修复点：当数据为空时，在这里占位，确保返回按钮依然在左侧
                    VStack {
                        Text("暂无赛程信息")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // --- 3. 原有的列表显示逻辑 (完全不动你的间距和比例) ---
                    // 左侧：赛程列表
                    LeftGroupListView(viewModel: viewModel)
                        .frame(width: UIScreen.main.bounds.width * 0.46)
                        .padding(.top, 12)
                    
                    // 中间：分割线
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.vertical, 12)

                    // 右侧：场次列表
                    VStack(spacing: 0) {
                        RightGameListView(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                    }
                }
            }
            .ignoresSafeArea(edges: .horizontal)
        }
        .fullScreenBackground(Color.white)
        .onAppear {
            viewModel.getMatchList()
            AppDelegate.orientationLock = .landscape
            setOrientation(.landscapeRight)
        }
    }
    private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            let rawValue = (orientation == .landscapeRight) ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}

// MARK: - 左侧列表 (拆分子视图以解决编译超时)
private struct LeftGroupListView: View {
    @ObservedObject var viewModel: LiveViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.matches) { match in
                    // 修复报错：将逻辑封装进独立的 MatchGroupRow
                    MatchGroupRow(
                        match: match,
                        isSelected: viewModel.selectedMatch?.id == match.id,
                        action: { viewModel.getSessionList(match: match) }
                    )
                }
            }
            .padding(.bottom, 12)
        }
    }
}

// 独立的左侧行视图
private struct MatchGroupRow: View {
    let match: MatchInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(match.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("比赛时间: \(match.startTimeString)")
                    Text("比赛组别: \(match.unitName)")
                    Text("比赛模式: \(match.modeName)，\(match.durationName)")
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            // 彻底解决编译：直接引用 ColorExtension 中的静态属性，不在此处做逻辑判断
            .background(
                Group {
                        if isSelected {
                            Color.orangeGradient
                        } else {
                            Color.white
                        }
                }
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.orange.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 25)   // 👈 修改：让左侧贴边（或者设为你想要的微小间距）
        .padding(.trailing, 15)  // 👈 修改：靠近中间分割线的地方保留一点间隙
    }
}

// MARK: - 右侧列表 (同样建议拆分以保持一致性)
private struct RightGameListView: View {
    @ObservedObject var viewModel: LiveViewModel

    var body: some View {
        if viewModel.selectedMatch != nil {
            if viewModel.isLoadingSessions {
                VStack {
                    ProgressView()
                    Text("加载场次中...").padding(.top)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sessions.isEmpty {
                Text("该赛程暂无场次信息").foregroundColor(.gray).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.sessions) { session in
                            SessionRow(session: session) {
                                
                                viewModel.confirmSelection(session: session)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        } else {
            VStack {
                Image(systemName: "arrow.left.to.line").font(.largeTitle).foregroundColor(.gray)
                Text("请先从左侧选择一个赛程").foregroundColor(.gray).padding(.top)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// 独立的右侧行视图
private struct SessionRow: View {
    let session: SessionItem
    let action: () -> Void
    
    // ✅ 1. 新增一个辅助方法，判断颜色Hex是否是纯白或近似白色
    private func isColorWhite(_ hex: String) -> Bool {
        let cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "").uppercased()
        return cleanHex == "FFFFFF" || cleanHex == "FFF"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                // --- 顶部：卡片头部 ---
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.orange)
                    Text(session.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    Spacer()
                    Text("共\(session.periods)节")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray.opacity(0.4))
                }
                
                // --- 核心：比分与队伍区域 ---
                // 使用 HStack(spacing: 0) + frame(maxWidth: .infinity) 确保绝对对称
                HStack(spacing: 0) {
                    
                    // 1. 主队区域 (占据左侧 50%)
                    HStack(spacing: 8) {
                        Spacer(minLength: 0) // 弹簧：将内容向右推，紧靠中间
                        
                        Text(session.homeTeamName)
                            .font(.system(size: 13))
                            .foregroundColor(.black)
                            .lineLimit(1) // 限制单行
                            .minimumScaleFactor(0.8) // 名字太长时自动缩小
                        
                        AsyncImage(url: URL(string: session.homeTeamAvatar)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Circle().fill(Color.gray.opacity(0.1))
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        
                        Text("\(session.homeScore)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: session.homeTeamColorHex))
                        // 如果是白色，加上黑色阴影模拟描边，否则不加
                            .shadow(color: isColorWhite(session.homeTeamColorHex) ? .black : .clear, radius: 1, x: 0.5, y: 0.5)
                            .shadow(color: isColorWhite(session.homeTeamColorHex) ? .black : .clear, radius: 1, x: -0.5, y: -0.5)
                            .frame(width: 36, alignment: .center)
                            .frame(width: 36, alignment: .center) // 固定宽度，防止抖动
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 2. 中间分隔
                    Text(":")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.3))
                        .frame(width: 16)
                    
                    // 3. 客队区域 (占据右侧 50%)
                    HStack(spacing: 8) {
                        Text("\(session.awayScore)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: session.awayTeamColorHex))
                            .shadow(color: isColorWhite(session.awayTeamColorHex) ? .black : .clear, radius: 1, x: 0.5, y: 0.5)
                            .shadow(color: isColorWhite(session.awayTeamColorHex) ? .black : .clear, radius: 1, x: -0.5, y: -0.5)
                            .frame(width: 36, alignment: .center) // 固定宽度
                        
                        AsyncImage(url: URL(string: session.awayTeamAvatar)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Circle().fill(Color.gray.opacity(0.1))
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        
                        Text(session.awayTeamName)
                            .font(.system(size: 13))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer(minLength: 0) // 弹簧：将内容向左推，紧靠中间
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            // 保持原有的背景色设置
            .background(Color.orangeGradientLess)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        // ❌ 这里原本是 .padding(.leading, 10).padding(.trailing, 8)
        .padding(.leading, 15)   // 👈 修改：靠近中间分割线保留一点间隙
        .padding(.trailing, 25)  // 👈 修改：让右侧卡片完全贴紧屏幕右边缘
    }
}
// 预览
struct MatchSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MatchSelectionView(viewModel: LiveViewModel())
    }
}
