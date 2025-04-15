
Pod::Spec.new do |s|
  s.name      = 'FSPagingKit'
  s.version   = '1.0.6'
  s.summary   = 'A container view controller that manages navigation between pages of content, where a child view controller manages each page.'
  s.homepage  = 'https://github.com/lifution/FSPagingKit'
  s.license   = { :type => 'MIT', :file => 'LICENSE' }
  s.author    = 'VicentLee'
  s.source    = {
    :git => 'https://github.com/lifution/FSPagingKit.git',
    :tag => s.version.to_s
  }
  s.swift_version = '5'
  s.requires_arc = true
  s.ios.deployment_target = '13.0'
  s.frameworks = 'UIKit', 'Foundation'
  s.source_files = 'FSPagingKit/Classes/**/*'
end
