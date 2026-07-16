#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tencent_effect_flutter.podspec` to validate before publishing.
#

require 'yaml'

project_root = ENV['FLUTTER_APPLICATION_PATH']
# 利用 CocoaPods 的 Config 实例找到 Podfile 所在的目录，宿主项目通常在 Podfile 的上一级
if project_root.nil? && defined?(Pod::Config)
  podfile_dir = Pod::Config.instance.project_root.to_s
  project_root = File.expand_path('..', podfile_dir)
end

puts "[TencentEffect] project_root: #{project_root}"
pubspec_path = File.join(project_root, 'pubspec.yaml') if project_root


sub_spec_version = 'S1-07'
ALLOWED_VERSIONS = [
  'A1-00', 'A1-01', 'A1-02', 'A1-03', 'A1-04', 'A1-05', 'A1-06',
  'S1-00', 'S1-01', 'S1-02', 'S1-03', 'S1-04', 'S1-05', 'S1-06', 'S1-07'
]

puts "---------------- [TencentEffect] ----------------"
if pubspec_path && File.exist?(pubspec_path)
  begin
    puts "[TencentEffect] path: #{pubspec_path}"
    pubspec = YAML.load_file(pubspec_path)
    if pubspec['TencentEffect'] && pubspec['TencentEffect']['te_sub_spec']
      parsed_version = pubspec['TencentEffect']['te_sub_spec']
      if ALLOWED_VERSIONS.include?(parsed_version)
        sub_spec_version = parsed_version
        puts "[TencentEffect] parsed success: #{sub_spec_version}"
      else
        sub_spec_version = 'S1-07'
        puts "[TencentEffect] warning: invalid sub_spec '#{parsed_version}', allowed: #{ALLOWED_VERSIONS.join(', ')}"
        puts "[TencentEffect] fallback to default: #{sub_spec_version}"
      end
    else
      puts "[TencentEffect] sub_spec not found, use default"
    end
  rescue => e
    puts "[TencentEffect] YAML parsed error: #{e.message}"
  end
else
  puts "[TencentEffect] warning: pubspec.yaml not found (path: #{pubspec_path})"
end
puts "-----------------------------------------------"

Pod::Spec.new do |s|
  s.name             = 'tencent_effect_flutter'
  s.version          = '4.3.0'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.default_subspec = sub_spec_version

  # 根据 ALLOWED_VERSIONS 自动生成所有 subspec
  ALLOWED_VERSIONS.each do |ver|
    s.subspec ver do |ss|
      ss.dependency "TencentEffect_#{ver}", '4.3.0.11'
    end
  end

  s.dependency 'TXCustomBeautyProcesserPlugin', '1.0.2'
  s.platform = :ios, '9.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
