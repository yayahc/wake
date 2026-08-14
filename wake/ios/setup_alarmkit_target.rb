#!/usr/bin/env ruby
# Configures the iOS project for AlarmKit:
#   1. creates the WakeAlarmWidget app-extension target
#   2. sets target membership on the shared AlarmKit sources
#   3. wires the App Group entitlements onto both targets
#   4. raises deployment targets to iOS 26.0
#
# Idempotent: re-running rebuilds the widget target from scratch.

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH   = File.expand_path('../ios/Runner.xcodeproj', __dir__)
DEPLOYMENT     = '26.0'
WIDGET         = 'WakeAlarmWidget'
APP_BUNDLE_ID  = 'dev.yayahc.wake'

project_path = ARGV[0] || PROJECT_PATH
abort "Project not found: #{project_path}" unless Dir.exist?(project_path)

pbxproj = File.join(project_path, 'project.pbxproj')
FileUtils.cp(pbxproj, "#{pbxproj}.bak") unless File.exist?("#{pbxproj}.bak")

project = Xcodeproj::Project.open(project_path)
ios_dir = File.dirname(project_path)

runner = project.targets.find { |t| t.name == 'Runner' } or abort 'No Runner target'

# ---------------------------------------------------------------- 4. deployment
puts '==> Raising deployment target to iOS 26.0'
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT
end
runner.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT
end

# ------------------------------------------------------- remove any prior widget
existing = project.targets.find { |t| t.name == WIDGET }
if existing
  puts "==> Removing existing #{WIDGET} target so it can be rebuilt cleanly"
  product = existing.product_reference
  project.targets.each do |t|
    t.build_phases.grep(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase).each do |phase|
      phase.files.select { |f| f.file_ref == product }.each(&:remove_from_project)
    end
    t.dependencies.select { |d| d.target == existing }.each(&:remove_from_project)
  end
  existing.remove_from_project
  product&.remove_from_project
end
project.main_group[WIDGET]&.remove_from_project

# ------------------------------------------------------------- 1. widget target
puts "==> Creating #{WIDGET} app-extension target"
widget = project.new_target(:app_extension, WIDGET, :ios, DEPLOYMENT)

# A dedicated xcconfig, NOT Runner's Debug/Release ones: those `#include` the
# Pods-Runner configs, which would link Flutter.framework and every pod into the
# appex. This one pulls in Generated.xcconfig only, so FLUTTER_BUILD_NAME /
# FLUTTER_BUILD_NUMBER still resolve in the extension's Info.plist.
flutter_group = project.main_group['Flutter']
# The Flutter group has no path of its own, so children carry the full relative path.
widget_xcconfig = flutter_group.files.find { |f| f.display_name == 'WakeAlarmWidget.xcconfig' } ||
                  flutter_group.new_reference('Flutter/WakeAlarmWidget.xcconfig')

team = runner.build_configurations
             .map { |c| c.build_settings['DEVELOPMENT_TEAM'] }
             .compact.first

widget.build_configurations.each do |config|
  config.base_configuration_reference = widget_xcconfig

  settings = config.build_settings
  settings['IPHONEOS_DEPLOYMENT_TARGET']   = DEPLOYMENT
  settings['PRODUCT_BUNDLE_IDENTIFIER']    = "#{APP_BUNDLE_ID}.#{WIDGET}"
  settings['PRODUCT_NAME']                 = '$(TARGET_NAME)'
  settings['INFOPLIST_FILE']               = "#{WIDGET}/Info.plist"
  settings['GENERATE_INFOPLIST_FILE']      = 'NO'
  settings['CODE_SIGN_ENTITLEMENTS']       = "#{WIDGET}/#{WIDGET}.entitlements"
  settings['CODE_SIGN_STYLE']              = 'Automatic'
  settings['SWIFT_VERSION']                = '5.0'
  settings['TARGETED_DEVICE_FAMILY']       = '1,2'
  settings['SKIP_INSTALL']                 = 'YES'
  settings['CLANG_ENABLE_MODULES']         = 'YES'
  settings['LD_RUNPATH_SEARCH_PATHS']      = ['$(inherited)', '@executable_path/Frameworks',
                                              '@executable_path/../../Frameworks']
  settings['DEVELOPMENT_TEAM'] = team if team
  # The widget links no pods; keep Flutter's pod search paths out of it.
  settings.delete('OTHER_LDFLAGS')
end

# ------------------------------------------------- 2. file refs + target membership
puts '==> Adding sources and setting target membership'

runner_group = project.main_group['Runner']
alarmkit_group = runner_group['AlarmKit'] || runner_group.new_group('AlarmKit', 'AlarmKit')

# file name => [in Runner?, in WakeAlarmWidget?]
SHARED_SOURCES = {
  'WakeAlarmShared.swift'     => [true,  true],
  'WakeAlarmController.swift' => [true,  true],
  'WakeAlarmIntents.swift'    => [true,  true],
  # imports Flutter; must stay out of the extension
  'WakeAlarmPlugin.swift'     => [true,  false],
}.freeze

SHARED_SOURCES.each do |name, (in_runner, in_widget)|
  path = File.join(ios_dir, 'Runner', 'AlarmKit', name)
  abort "Missing source: #{path}" unless File.exist?(path)

  ref = alarmkit_group.files.find { |f| f.display_name == name } ||
        alarmkit_group.new_reference(name)

  runner.add_file_references([ref]) if in_runner &&
    runner.source_build_phase.files_references.none? { |r| r == ref }
  widget.add_file_references([ref]) if in_widget
  puts "    #{name.ljust(28)} Runner=#{in_runner ? 'yes' : 'no '} #{WIDGET}=#{in_widget ? 'yes' : 'no'}"
end

widget_group = project.main_group.new_group(WIDGET, WIDGET)
%w[WakeAlarmWidgetBundle.swift WakeAlarmLiveActivity.swift].each do |name|
  path = File.join(ios_dir, WIDGET, name)
  abort "Missing source: #{path}" unless File.exist?(path)
  widget.add_file_references([widget_group.new_reference(name)])
  puts "    #{name.ljust(28)} Runner=no  #{WIDGET}=yes"
end
# Non-compiled members of the widget group, for visibility in Xcode.
%w[Info.plist WakeAlarmWidget.entitlements].each do |name|
  widget_group.new_reference(name)
end

# ------------------------------------------------------------- 3. App Group entitlements
puts '==> Attaching App Group entitlements'
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
unless runner_group.files.any? { |f| f.display_name == 'Runner.entitlements' }
  runner_group.new_reference('Runner.entitlements')
end

# Register the App Groups capability so Xcode's UI reflects it too.
project.root_object.attributes['TargetAttributes'] ||= {}
[runner, widget].each do |target|
  attrs = project.root_object.attributes['TargetAttributes'][target.uuid] ||= {}
  attrs['DevelopmentTeam'] = team if team
  caps = attrs['SystemCapabilities'] ||= {}
  caps['com.apple.ApplicationGroups.iOS'] = { 'enabled' => 1 }
end

# ------------------------------------------------------------- embed the extension
puts '==> Embedding the extension into Runner'
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
embed ||= begin
  phase = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  phase.symbol_dst_subfolder_spec = :plug_ins
  phase
end
embed.files.each(&:remove_from_project)
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.add_dependency(widget)

# Flutter's "Thin Binary" phase reads Runner.app, so embedding after it is a
# dependency cycle. The appex has to land in PlugIns before thinning runs.
thin_index = runner.build_phases.index { |p| p.display_name == 'Thin Binary' }
if thin_index
  runner.build_phases.delete(embed)
  runner.build_phases.insert(thin_index, embed)
  puts '    moved Embed Foundation Extensions before Thin Binary'
end

project.save
puts "==> Saved #{pbxproj}"
