#
#  Be sure to run `pod spec lint bell.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "bell"
  s.version      = "0.0.1"
  s.summary      = "A simple wrapper of AVFoundation's audio part with volume in/out effect"

  s.homepage     = "https://github.com/xiuxiude/bell"
  s.license      = { :type => 'BSD', :file => 'LICENSE'} 
  s.author       = { "Chase Zhang" => "yun.er.run@gmail.com",
                    "AnakinMac" => "anakinmac@gmail.com"}
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'
  s.source       = { :git => "git@github.com:xiuxiude/bell.git", :tag => "0.0.1" }
  s.source_files  = 'src'
  s.exclude_files = 'BellDemo'
  s.frameworks = 'AVFoundation', 'CoreMedia'
  s.requires_arc = true

end
