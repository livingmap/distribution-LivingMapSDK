Pod::Spec.new do |spec|
  spec.ios.deployment_target      = '10.0'
  spec.name                       = 'LivingMapSDK'
  spec.version                    = '1.4.6'
  spec.license                    = { :type => 'Copyright', :text => 'Living Map' }
  spec.homepage                   = 'http://www.livingmap.com'
  spec.authors                    = { 'Living Map' => 'tech@livingmap.com' }
  spec.summary                    = 'LivingMapSDK 1.4.6 for iOS10.0 and above'
  spec.source                     = { :git => 'git@github.com:livingmap/distribution-LivingMapSDK.git', :tag => spec.version }
  spec.swift_version              = '5.0'
  spec.frameworks                 = 'WebKit', 'Foundation'
  spec.vendored_frameworks        = 'LivingMapSDK.framework'
  spec.dependency                   'SwiftProtobuf'
  spec.dependency                   'Alamofire'
end
