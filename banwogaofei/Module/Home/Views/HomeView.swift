import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    
    @State private var isShowingLivePreview = false  // 控制“比赛直播”
    @State private var isShowingClassCapture = false // 控制“课堂拍摄”
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Section (Orange Background)
                ZStack(alignment: .top) {
                    Color(hex: "FFA313")
                        .edgesIgnoringSafeArea(.top)
                    
                    VStack(spacing: 20) {
                        // Custom Navigation Bar
                        HStack {
                            Button(action: {
                                viewModel.switchRole()
                            }) {
                                HStack(spacing: 4) {
                                    Image("dingwei") // "Switch" icon placeholder
                                        .font(.system(size: 16))
                                    Text("切换")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Logo/Title in Center
                            VStack(spacing: 2) {
                                Image("logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(.top,Screen.adapt(10))
                                    
                                    
                            }
                            
                            Spacer()
                            
                            // Hidden placeholder to balance title centering if needed, or just Spacer
                            Color.clear.frame(width: 60, height: 1)
                        }
                        .padding(.horizontal,Screen.adapt(10))
                        .padding(.top, Screen.adapt(5)) // Adjust for safe area if needed
                        
                        // User Profile Section
                        HStack(spacing: Screen.adapt(10)) {
                            // 头像部分
                            AsyncImage(url: URL(string: viewModel.currentUser?.avatar ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Image("avatar_placeholder") // 你的占位图名称
                                    .resizable()
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            
                            // 展示用户信息的部分
                            VStack(alignment: .leading, spacing: 4) {
                                // 展示真实姓名，如果没有则显示默认值
                                Text(viewModel.currentUser?.name ?? "未登录")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                // 展示真实角色名称
                                Text(viewModel.currentUser?.role == 1 ? "校长" :"普通成员")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, Screen.adapt(20))
                        .padding(.bottom, Screen.adapt(20))
                    }
                }
                .frame(height: Screen.adapt(160)) // Adjust height as per design
                
                // Bottom Section (White Background with Cards)
                VStack {
                    HStack(spacing: 20) {
                        
                        // Card 1: 课堂拍摄
                        Button(action: {
                            isShowingClassCapture = true}){
                                ServiceCard(
                                    title: "课堂拍摄",
                                    iconName: "ketang", // Placeholder system icon
                                    color: AnyView(
                                        LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#FFF7EB"), Color(hex: "#FFFCF8")]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                )
                            }
                        .buttonStyle(PlainButtonStyle())
                       
                        
                        // Card 2: 比赛直播
                        Button(action: {
                            // 关键修复：在弹出 Cover 之前，立即锁定为横屏，防止竖屏启动闪烁
                            AppDelegate.orientationLock = .landscapeRight
                            isShowingLivePreview = true}){
                                ServiceCard(
                                    title: "比赛直播",
                                    iconName: "bisia", // Placeholder system icon
                                    color: AnyView(
                                        LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#FFF7EB"), Color(hex: "#FFFCF8")]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                )
                            }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .background(Color.white)
            }
            .navigationBarHidden(true)
            // 弹窗 A: 比赛直播预览
            .fullScreenCover(isPresented: $isShowingLivePreview) {
                            LiveView()
                        }
                // 弹窗 B: 课堂拍摄页面（假设你创建了一个 ClassCaptureView）
                .fullScreenCover(isPresented: $isShowingClassCapture) {
                    Text("这里是课堂拍摄界面")
                    // 未来替换为：ClassCaptureView()
                }
        }
    }
}

struct ServiceCard: View {
    let title: String
    let iconName: String
    let color: AnyView // 修改为支持任意 View
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FFECC7")) // Lighter orange for circle background
                    .frame(width: 80, height: 80)
                
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color(hex: "FFA313"))
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(color) // 支持渐变色
        .cornerRadius(12)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
