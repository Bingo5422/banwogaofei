import SwiftUI
import Combine

// 定义 App 中所有可能的顶级页面
enum AppView {
    case login
    case home

}

class Router: ObservableObject {
    // 修改初始值逻辑
    @Published var currentView: AppView
    
    init() {
        // 核心逻辑：判断用户是否已登录（UserManager 内部会自动 loadUser）
        if UserManager.shared.isLoggedIn {
            self.currentView = .home
        } else {
            self.currentView = .login
        }
    }

    func navigateTo(_ view: AppView) {
        DispatchQueue.main.async {
            self.currentView = view
        }
    }
    // 新增：供外部调用的状态刷新
    func updateLoginStatus() {
            if UserManager.shared.isLoggedIn {
                self.navigateTo(.home)
            }
    }
}
