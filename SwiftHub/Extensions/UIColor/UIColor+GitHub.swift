//
//  UIColor+GitHub.swift
//  SwiftHub
//
//  GitHub Primer 色板（对照官方 iOS 客户端 1.282.0 的视觉规范）
//  浅色 / 深色两套，命名沿用 Primer 语义：canvas / fg / border / accent
//

import UIKit

extension UIColor {

    enum GitHub {

        // MARK: - 浅色（Light）

        /// 页面底色
        static let canvasDefault = UIColor(githubHex: 0xFFFFFF)
        /// 次级底色：分组背景、搜索框、TabBar
        static let canvasSubtle = UIColor(githubHex: 0xF6F8FA)
        /// 内嵌区域
        static let canvasInset = UIColor(githubHex: 0xF6F8FA)
        /// 描边
        static let borderDefault = UIColor(githubHex: 0xD0D7DE)
        static let borderMuted = UIColor(githubHex: 0xD8DEE4)
        /// 正文
        static let fgDefault = UIColor(githubHex: 0x1F2328)
        /// 次要文字
        static let fgMuted = UIColor(githubHex: 0x656D76)
        /// 链接 / 强调
        static let accent = UIColor(githubHex: 0x0969DA)
        static let accentEmphasis = UIColor(githubHex: 0x0969DA)
        static let accentMuted = UIColor(githubHex: 0xDDF4FF)
        static let success = UIColor(githubHex: 0x1F883D)
        static let danger = UIColor(githubHex: 0xCF222E)
        static let attention = UIColor(githubHex: 0x9A6700)

        // MARK: - 深色（Dark）

        static let darkCanvasDefault = UIColor(githubHex: 0x0D1117)
        static let darkCanvasSubtle = UIColor(githubHex: 0x161B22)
        static let darkCanvasInset = UIColor(githubHex: 0x010409)
        static let darkBorderDefault = UIColor(githubHex: 0x30363D)
        static let darkFgDefault = UIColor(githubHex: 0xE6EDF3)
        static let darkFgMuted = UIColor(githubHex: 0x8B949E)
        static let darkAccent = UIColor(githubHex: 0x2F81F7)
        static let darkSuccess = UIColor(githubHex: 0x3FB950)

        // MARK: - 语义色（语言点等）

        static let languageDotFallback = UIColor(githubHex: 0x8B949E)
    }
}

// MARK: - Hex 初始化

extension UIColor {

    convenience init(githubHex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((githubHex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((githubHex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(githubHex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

}
