
Pod::Spec.new do |s|
  s.name      = 'FSPagingKit'
  s.version   = '1.0.0'
  s.summary   = 'A container view controller that manages navigation between pages of content, where a child view controller manages each page. (like UIKit/UIPageViewController)'
  s.homepage  = 'https://github.com/Sheng/FSPagingKit'
  s.license   = { :type => 'MIT', :file => 'LICENSE' }
  s.author    = 'Sheng'
  s.source    = {
    :git => 'git@github.com:lifution/FSPagingKit.git',
    :tag => s.version.to_s
  }
  
  s.swift_version = '5'
  s.ios.deployment_target = '11.0'
  
  s.frameworks = 'UIKit', 'Foundation'

  s.source_files = 'FSPagingKit/Classes/**/*'
end
