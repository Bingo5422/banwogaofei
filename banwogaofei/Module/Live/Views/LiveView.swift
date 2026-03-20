import SwiftUI
import TXLiteAVSDK_Professional

struct LiveView: View {
    @Environment(\.presentationMode) var presentationMode
    // 1. 引入推流管理器
    @StateObject private var pusherManager = LivePusherManager()
    @StateObject private var viewModel = LiveViewModel()
    
    
    // ✅ 新增：推流和弹窗状态控制
    @State private var pushingMatchId: Int? = nil // 当前推流的左侧赛程ID
    
    @Environment(\.scenePhase) var scenePhase // ✅ 新增1：监听系统后台/前台状态
    @State private var showExitAlert = false // ✅ 新增2：控制退出确认弹窗的显示状态
    

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                

                // 表层：UI 控件层
                VStack {
                    // 顶部栏
                    HStack {
                            // 返回/关闭按钮
                            Button(action: {
                                if pusherManager.isPushing {
                                    // ✅ 如果正在直播中，弹出确认框，不直接退出
                                    showExitAlert = true
                                } else {
                                    
                                    // ✅ 如果没有在直播，直接执行退出并断开WebSocket
                                    closeLiveView()
                                }
                            }) {
                                Image(systemName: "xmark")
                                //... 后续的UI代码保持不变 (不要动UI代码)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                        }
                        .padding(.leading, geometry.safeAreaInsets.leading > 0 ? 10 : 20)

                        Spacer()

                        
                        Group { // ✅ 用 Group 包裹不同状态的内容
                            if pusherManager.isPushing {
                                // 连接成功的状态
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green) // 绿色小圆点
                                        .frame(width: 8, height: 8)
                                    Text("推流已连接")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            } else {
                                // 默认状态
                                Text("视频预览模式已启动")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                        .padding(.trailing, geometry.safeAreaInsets.trailing > 0 ? 10 : 20)
                    }
                    .padding(.top, 15)
                    

                    Spacer()

                    if viewModel.currentSession == nil{
                        // 未选中比赛：屏幕正中间显示大按钮

                        VStack(spacing: 15){
                            Spacer()
                            matchSelectionLabel
                                .onTapGesture {
                                    viewModel.isShowingMatchList = true
                                }
                            Spacer()
                        }
                        .frame(width: 300, height: 100)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                    }

                    Spacer()

                    // 底部控制项：使用 Spacer 撑开左右两端
                    HStack(alignment: .bottom) {
                        
                        // 1. 左下角：分辨率切换菜单
                        resolutionMenu
                       
                        // 适配横屏下的刘海边距
                        .padding(.leading, geometry.safeAreaInsets.leading > 0 ? 0 : 20)
                        
                        
                        
                        Spacer(minLength: 1) // 给中间留点弹性空间
                            
                        // ✅ 2. 新增：将记分牌嵌在这里（两个按钮组之间）
                        if let session = viewModel.currentSession {
                            
                            overlayScoreboardView
                            
                                .layoutPriority(1) // 提高优先级，防止被两边按钮挤压 // 限制一下最大宽度，防止把左右按钮挤出屏幕
                                
                        }
                        
                        Spacer(minLength: 1)

                        // 2. 右下角：功能按键组
                        HStack(spacing: 5) {
                            // ✅ 3. 修改：让右侧按钮真正触发弹窗
                            Button(action: {
                                viewModel.isShowingMatchList = true
                            }) {
                                CircularButton(title: "选择\n比赛")
                            }

                            Button(action: {
                                if pusherManager.isPushing {
                                    pusherManager.stopPush()
                                    viewModel.disconnectWebSocket()
                                } else {
                                    // 使用左侧选中的比赛 ID 作为流名
                                    guard let matchId = viewModel.selectedMatch?.id else {
                                        print("❌ 错误：未选中左侧比赛，无法获取流名")
                                        return
                                    }
                                    viewModel.reconnectWebSocket()
                                    // 使用 String进行转换
                                    let streamName = String(matchId)
                                    // 生成推流地址
                                    let url = PushUrlGenerator.generatePushUrl(streamName: streamName)
                                    // 记录当前推流的赛程ID
                                    pushingMatchId = matchId
                                    pusherManager.startPush(url: url)
                                    
                                    // 2. 初始渲染水印
                                    if let session = viewModel.currentSession {
                                        // 创建水印视图
                                        let overlay = overlayScoreboardView
                                        .background(Color.clear)
                                        .environment(\.colorScheme, .dark)
                                        
                                        // ✅ 关键修改：直接调用我们刚刚在 Manager 中新增的方法
                                        // 不需要再包裹 DispatchQueue，因为 Manager 内部已经处理了
                                        pusherManager.updateScoreboardWatermark(from: overlay)
                                    }
                                   
                                }
                            }) {
                                CircularButton(
                                    title: pusherManager.isPushing ? "停止\n直播" : "开始\n直播",
                                    isPrimary: true
                                )
                            }
                        }
                        // 适配横屏下的右侧边距
                        .padding(.trailing, geometry.safeAreaInsets.trailing > 0 ? 0 : 20)
                    }
                    .padding(.horizontal, 5)
                    .padding(.bottom, 15)
                }
                
                
            }
        }
        .onChange(of: viewModel.realTimeData) { newData in
            // 1. 增加状态校验，只有在推流成功且数据有效时才处理
            guard pusherManager.isPushing, let session = viewModel.currentSession, let safeData = newData else { return }
            
            // 2. 严禁直接在这里写渲染逻辑，必须异步分发，且降低频率
            // 建议：如果你能感知比分没变，就直接 return
            
            DispatchQueue.global(qos: .userInteractive).async {
                let overlay = overlayScoreboardView
                // 渲染是耗时的，放到主线程异步执行，不要阻塞当前的 WebSocket 数据处理循环
                DispatchQueue.main.async {
                    pusherManager.updateScoreboardWatermark(from: overlay)
                }
            }
        }
        // 【新增监听：当得分事件出现或消失时，必须强制刷新推流画面的水印】
        .onChange(of: viewModel.currentScoreEvent) { _ in
            guard pusherManager.isPushing, viewModel.currentSession != nil else { return }
            
            // 确保在主线程组装 UI 并推给推流器
            DispatchQueue.main.async {
                let overlay = overlayScoreboardView
                    .background(Color.clear)
                    .environment(\.colorScheme, .dark)
                
                pusherManager.updateScoreboardWatermark(from: overlay)
            }
        }
    
        // 在已有的 .onChange(of: viewModel.realTimeData) 下方添加
        .onChange(of: pusherManager.isPushing) { pushing in
            // 当推流状态变为 true 时，主动触发一次水印渲染
            if pushing, let session = viewModel.currentSession {
                let overlay = overlayScoreboardView
                .background(Color.clear)
                .environment(\.colorScheme, .dark)
                
                DispatchQueue.main.async {
                    pusherManager.updateScoreboardWatermark(from: overlay)
                }
            }
        }
        // 【1】监听场次切换，处理是否需要重新推流
        .onChange(of: viewModel.currentSession?.key) { _ in
            guard pusherManager.isPushing else { return }
            guard let newMatchId = viewModel.selectedMatch?.id else { return }
            
            // 只有当属于不同的 Match 赛程时，才断开重新推流
            if pushingMatchId != newMatchId {
                print("🔄 赛程发生变化，正在重新推流...")
                pusherManager.stopPush()
                
                let streamName = String(newMatchId)
                let url = PushUrlGenerator.generatePushUrl(streamName: streamName)
                pusherManager.startPush(url: url)
                
                pushingMatchId = newMatchId // 更新记录
            }
        }
        

        
        
        
        
        
                // 3. 挂载弹窗：展示比赛列表
        .sheet(isPresented: $viewModel.isShowingMatchList) {
            MatchSelectionView(viewModel: viewModel)
        }
        .onAppear {
            // 1. 立即锁定允许的方向为横屏
            AppDelegate.orientationLock = .landscape
            
            // 2. 立即请求旋转
            DispatchQueue.main.async {
                setOrientation(.landscapeRight)
            }
        }
        .fullScreenBackground(
            TencentCameraPreview(manager: pusherManager)
            .ignoresSafeArea()
        )
        .onDisappear {
            // 1. 先将锁改回竖屏，确保系统知道接下来“只允许”竖屏
            AppDelegate.orientationLock = .portrait
            
            // 2. 强制旋转回竖屏
            setOrientation(.portrait)
            
            // 3. 关键补丁：通知系统重新评估所有窗口的方向限制
            // 这能解决“返回主页仍是横屏”的问题
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                UIViewController.attemptRotationToDeviceOrientation()
            }
            
            // 停止推流逻辑保持不变...
            pusherManager.stopPush()
            pusherManager.stopLocalPreview()
            // ✅ 防御性编程：页面彻底消失时确保断开
            viewModel.disconnectWebSocket()
        }
        // 👇 从这里开始是新增内容 👇
        .alert(isPresented: $showExitAlert) {
            Alert(
                title: Text("提示"),
                message: Text("当前正在直播中，确定要结束直播并退出页面吗？"),
                primaryButton: .destructive(Text("确定退出")) {
                    closeLiveView() // 确认退出
                },
                secondaryButton: .cancel(Text("继续直播"))
            )
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // ✅ App从后台切回前台时，自动重连 WebSocket
                viewModel.reconnectWebSocket()
            } else if newPhase == .background {
                // ✅ App进入后台时，主动断开以防系统挂起导致异常
                viewModel.disconnectWebSocket()
            }
        }
    }
    
    // ✅ 新增：统一提取的退出逻辑，方便复用
        private func closeLiveView() {
            // 1. 明确断开 WebSocket
            viewModel.disconnectWebSocket()
            // 2. 停止推流
            pusherManager.stopPush()
            // 3. 恢复全局竖屏锁定
            AppDelegate.orientationLock = .portrait
            setOrientation(.portrait)
            // 4. 执行关闭
            presentationMode.wrappedValue.dismiss()
        }

    
    
    // 抽离的分辨率选择菜单，彻底移除对腾讯云枚举的依赖
    private var resolutionMenu: some View {
        Menu {
            Button(action: { pusherManager.setResolution(to1080P: true) }) {
                HStack {
                    Text("1080P 超清")
                    if pusherManager.is1080P {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { pusherManager.setResolution(to1080P: false) }) {
                HStack {
                    Text("720P 高清")
                    if !pusherManager.is1080P {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            // ✨ 逻辑极度简化，只判断一个 Bool
            CircularButton(
                title: "清晰度\n\(pusherManager.is1080P ? "1080P" : "720P")",
                isSelected: true
            )
        }
        // ⚠️ 如果之前加了 .id() 修饰符，请务必删除，不再需要了
    }
    
    
    // 2. 在 body 块外（LiveView 内部）定义这个变量
    private var overlayScoreboardView: some View {
        // 这里的 if let 是根据你代码中的逻辑而定，确保 session 存在
        if let session = viewModel.currentSession {
            return AnyView(
                ScoreboardView(
                    session: session,
                    realTimeData: viewModel.realTimeData,
                    matchName: viewModel.selectedMatch?.name ?? "赛事名称",
                    scoreEvent: viewModel.currentScoreEvent,
                    timeoutEvent: viewModel.currentTimeoutEvent
                )
            )
        }
        return AnyView(EmptyView())
    }
    
    private func syncDataToPusher() {
            // 如果有实时数据，将其转为 JSON 字符串并“打包”发送
            if let data = viewModel.realTimeData {
                let encoder = JSONEncoder()
                // 保持字段格式与后端一致（下划线格式）
                encoder.keyEncodingStrategy = .convertToSnakeCase
                
                if let jsonData = try? encoder.encode(data),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    pusherManager.sendMetadataToStream(jsonString)
                }
            }
    }
    
    // 优化后的旋转函数：增加了对 KeyWindow 的强制刷新
    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            // 请求几何更新
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            
            // 核心补丁：强制根控制器重新评估方向，解决“无法回正”的顽疾
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(orientation == .landscapeRight ?
                                     UIInterfaceOrientation.landscapeRight.rawValue :
                                     UIInterfaceOrientation.portrait.rawValue,
                                     forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    // 在 LiveView 内部定义一个计算属性，专门负责按钮文字逻辑
    private var matchSelectionLabel: some View {
        HStack {
            Image(systemName: "list.bullet.clipboard")
            Text("选择要直播的比赛")
        }
        .font(.system(size: 14))
        .foregroundColor(.white)
        .padding(.horizontal, 30)
        .padding(.vertical, 6)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 1))
    }
    

    
}

struct CircularButton: View {
    let title: String
    var isPrimary: Bool = false
    var isSelected: Bool = false // ✨ 新增：选中状态
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: isSelected ? .bold : .regular))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .frame(width: 60, height: 60)
            .background(
                // 如果是主按钮（开始/停止）或者是选中状态的分辨率按钮，显示橙色
                (isPrimary || isSelected) ? Color(hex: "FFA313") : Color.black.opacity(0.5)
            )
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white.opacity(isSelected ? 1.0 : 0.6),
                               lineWidth: isSelected ? 2 : 1)
            )
    }
}
// 预览
struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

