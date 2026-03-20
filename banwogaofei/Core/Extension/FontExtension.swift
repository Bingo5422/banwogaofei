//
//  FontExtension.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/18.
//

import SwiftUI

extension Font {
    
    /// 金刚体 - 适用于标题、球队名称等强调文本
    static func cktKingkong(size: CGFloat) -> Font {
        return .custom("CKTKingkong", size: size) // 对应 CKTKingkong.ttf
    }
    
    /// DIN Cond Black - 窄体加粗，非常适合比分（Scoreboard）、计时器数字
    static func dinCondBlack(size: CGFloat) -> Font {
        return .custom("DINCond-Black", size: size) // 对应 DINCond-Black.otf
    }
    
    /// 可选：如果需要支持加粗等动态缩放，可以封装这个通用方法
    private static func custom(_ name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        return .custom(name, size: size, relativeTo: textStyle)
    }
}

// MARK: - 快捷使用示例 (ViewModifier)
extension View {
    func cktFont(size: CGFloat = 17) -> some View {
        self.font(.cktKingkong(size: size)) // 快速设置金刚体
    }
    
    func scoreFont(size: CGFloat = 24) -> some View {
        self.font(.dinCondBlack(size: size)) // 快速设置比分数字体
    }
}
