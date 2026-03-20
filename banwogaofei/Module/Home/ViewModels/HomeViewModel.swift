import Foundation
import Combine

class HomeViewModel: ObservableObject {
    // 1. 将 currentUser 改为可选型，初始值从 UserManager 获取
    @Published var currentUser: CoachInfo?
    @Published var item: [functionItem] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 2. 绑定 UserManager 的数据到当前 ViewModel
        UserManager.shared.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
        
        // 模拟业务数据保持不变
        self.item = [
            functionItem(id: "1", title: "课堂拍摄", iconName: "basketball"),
            functionItem(id: "2", title: "比赛直播", iconName: "trophy")
        ]
    }
    
    func switchRole() {
        print("切换角色逻辑")
    }
}
