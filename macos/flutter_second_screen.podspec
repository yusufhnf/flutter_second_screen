#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_second_screen.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_second_screen'
  s.version          = '2.0.0-dev.2'
  s.summary          = 'Secondary screen windows and cross-screen communication for Flutter desktop.'
  s.description      = <<-DESC
Secondary screen windows, multi-display detection, and cross-screen communication for Flutter desktop.
                       DESC
  s.homepage         = 'https://github.com/yusufhnf/flutter_second_screen'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'yusufhnf' => 'https://github.com/yusufhnf' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_second_screen/Sources/flutter_second_screen/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
