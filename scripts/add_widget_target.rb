#!/usr/bin/env ruby
# 为 SwiftHub 工程添加 WidgetKit 扩展 target（幂等，可重复执行）
require 'xcodeproj'

PROJECT = 'SwiftHub.xcodeproj'
TARGET_NAME = 'SwiftHubWidget'
BUNDLE_ID = 'com.public.SwiftHub.widget'
GROUP_NAME = 'SwiftHubWidget'
SOURCES = %w[
  SwiftHubWidget/SwiftHubWidget.swift
  SwiftHubWidget/TrendingProvider.swift
  SwiftHubWidget/TrendingViews.swift
  SwiftHubWidget/TrendingModels.swift
  SwiftHubWidget/TrendingService.swift
]

project = Xcodeproj::Project.open(PROJECT)
app = project.targets.find { |t| t.name == 'SwiftHub' }
abort '未找到 SwiftHub target' unless app

widget = project.targets.find { |t| t.name == TARGET_NAME }
if widget.nil?
  widget = project.new_target(:app_extension, TARGET_NAME, :ios, '15.4')
  puts "创建 target: #{TARGET_NAME}"
else
  puts "target 已存在: #{TARGET_NAME}"
end

# 1) 分组与源文件
group = project.main_group.find_subpath(GROUP_NAME, true)
group.set_source_tree('<group>')
group.path = GROUP_NAME if group.path.nil?

added = []
SOURCES.each do |rel|
  name = File.basename(rel)
  next if group.files.any? { |f| f.path == name }
  ref = group.new_file(name)
  widget.add_file_references([ref])
  added << name
end
puts "新增源文件: #{added.join(', ')}" unless added.empty?

# 2) 编译设置
widget.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = "#{GROUP_NAME}/Info.plist"
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.4'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_STYLE'] = 'Manual'
  s['CODE_SIGN_IDENTITY'] = '-'
  s['CODE_SIGNING_REQUIRED'] = 'NO'
  s['CODE_SIGNING_ALLOWED'] = 'NO'
  s['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  s['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if config.name == 'Debug'
  # 与主 App 保持同一套警告策略，避免 Pods 之外的额外噪音
  s['CLANG_ENABLE_MODULES'] = 'YES'
end

# 3) 嵌入到 App 的 PlugIns 目录
embed = app.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
if embed.nil?
  embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.dst_subfolder_spec = '13' # PlugIns
end
unless embed.files.any? { |f| f.display_name == "#{TARGET_NAME}.appex" }
  build_file = embed.add_file_reference(widget.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts '已加入 Embed Foundation Extensions'
end

# 4) 依赖关系
unless app.dependencies.any? { |d| d.target == widget }
  app.add_dependency(widget)
  puts '已建立 target 依赖'
end

project.save
puts "保存完成。targets: #{project.targets.map(&:name).join(', ')}"
