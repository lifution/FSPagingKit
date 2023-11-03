
Pod::Spec.new do |s|
  s.name      = 'FSPagingKit'
  s.version   = '1.0.0'
  s.summary   = 'A short description of FSPagingKit.'
  s.homepage  = 'https://github.com/Sheng/FSPagingKit'
  s.license   = { :type => 'MIT', :file => 'LICENSE' }
  s.author    = 'Sheng'
  s.source    = {
    :git => 'https://github.com/Sheng/FSPagingKit.git',
    :tag => s.version.to_s
  }
  
  s.swift_version = '5'
  s.ios.deployment_target = '13.0'
  
  s.frameworks = 'UIKit', 'Foundation'

  s.source_files = 'FSPagingKit/Classes/**/*'
end
