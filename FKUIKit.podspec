Pod::Spec.new do |s|
  s.name = 'FKUIKit'
  s.version = '0.66.0'
  s.summary = 'FKKit UIKit components: presentation, toast, and more.'
  s.description = <<-DESC
    Reusable UIKit building blocks from FKKit (ActionSheet,
    Badge, BlurView, Button, PresentationController, Refresh, TabBar, Toast, and more).
    Depends on FKCoreKit (same repository and tag).
  DESC
  s.homepage = 'https://github.com/feng-zhang0712/FKKit'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Feng Zhang' => 'https://github.com/feng-zhang0712' }
  s.source = { :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => s.version.to_s }
  s.platform = :ios, '15.0'
  s.swift_version = '6.0'
  s.requires_arc = true

  s.dependency 'FKCoreKit', s.version.to_s

  s.source_files = 'Sources/FKUIKit/**/*.swift'
  s.resource_bundles = {
    'FKUIKit' => ['Sources/FKUIKit/Resources/Assets.xcassets']
  }
end
