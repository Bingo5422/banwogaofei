//
//  UIDefines.swift
//  banwogaofei
//
//  Created by yuyu on 2026/3/5.
//

import SwiftUI

// 1. 屏幕尺寸与缩放工具
struct Screen {
    static let width = UIScreen.main.bounds.width
    static let height = UIScreen.main.bounds.height
    
    // 对应原文件中的 kScale (以 375.0 为基准)
    static let scale = width / 375.0
    
    // 对应原文件中的 kScaling(f)
    static func adapt(_ size: CGFloat) -> CGFloat {
        return size * scale
    }
}

// 2. 颜色适配 (将原文件中的 Hex 转换为 SwiftUI Color)
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8) / 255.0
        let b = Double(hex & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
    
    // 对应原文件中的常用色
    static let theme = Color(hex: 0x1D3E67)
    static let themeBackground = Color(hex: 0xF3F3F3)
    static let textDark = Color(hex: 0x333333)
    static let textGray = Color(hex: 0x999999)
}

// 3. 字体适配
extension Font {
    static func pingFang(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // 对应 kFontNamePingFangSCRegular 等
        let finalSize = Screen.adapt(size)
        return .custom("PingFang SC", size: finalSize).weight(weight)
    }
}
