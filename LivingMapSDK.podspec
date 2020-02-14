Pod::Spec.new do |spec|
  spec.ios.deployment_target      = '10.0'
  spec.name                       = 'LivingMapSDK'
  spec.version                    = '0.1.4'
  spec.license                    = { :type => 'Copyright', :text => 'Living Map' }
  spec.homepage                   = 'http://www.livingmap.com'
  spec.authors                    = { 'Living Map' => 'tech@livingmap.com' }
  spec.summary                    = 'LivingMapSDK 1.4.2 for iOS10.0 and above'
  spec.source                     = { :git => 'git@github.com:livingmap/mobile-mono-distribution-LivingMapSDK.git', :tag => spec.version }
  spec.frameworks                 = 'WebKit', 'Foundation'
  spec.vendored_frameworks        = 'LivingMapSDK.framework'
  spec.dependency                   'SwiftProtobuf'
  spec.dependency                   'Alamofire', '~> 5.0.0-rc.3'
end
