platform :ios, '15.6'
use_frameworks!

# 修复版：兼容 CocoaPods 1.16+ 的 post_install 配置
post_install do |installer|
  # 1. 统一所有 Pod Target 的部署版本和 Bitcode（核心）
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 强制设置为 15.6，解决 libarclite 问题
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
      # 关闭 Bitcode（老库不支持，避免额外报错）
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      # 关闭 workspace 验证（避免依赖冲突）
      config.build_settings['VALIDATE_WORKSPACE'] = 'NO'
    end
  end

  # 2. 手动加载主项目，统一 Tests/UITests Target 版本（兼容新版 CocoaPods）
  require 'xcodeproj'
  main_project_path = 'banwogaofei.xcodeproj' # 替换为你的主项目文件名
  main_project = Xcodeproj::Project.open(main_project_path)
  
  main_project.targets.each do |target|
    # 覆盖 Tests/UITests Target 的部署版本
    if target.name.include?('Tests') || target.name.include?('UITests')
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
      end
    end
    # 同时确保主 Target 版本一致（兜底）
    if target.name == 'banwogaofei'
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
      end
    end
  end
  main_project.save # 保存主项目配置修改
end

target 'banwogaofei' do
 # pod 'TUILiveKit'
  pod 'TXLiteAVSDK_Professional' # 腾讯云直播专业版 SDK
  pod 'Alamofire'
  pod 'Kingfisher'
  pod 'WechatOpenSDK'

  target 'banwogaofeiTests' do
    inherit! :search_paths
  end

  target 'banwogaofeiUITests' do
    inherit! :search_paths
  end
end