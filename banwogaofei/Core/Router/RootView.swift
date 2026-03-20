//
//  RootView.swift
//  banwogaofei
//
//  Created by GitHub Copilot on 2024/09/24.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: Router

//    var body: some View {
//        Group {
//            switch router.currentView {
//            case .login:
//                LoginView()
//            case .home:
//                HomeView()
//                    
//
//            }
//        }
//    }
    
    var body: some View {
        // 使用带有动画的切换，视觉效果更好
        ZStack {
            switch router.currentView {
            case .login:
                LoginView()
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.default, value: router.currentView)
    }
    
    
}

