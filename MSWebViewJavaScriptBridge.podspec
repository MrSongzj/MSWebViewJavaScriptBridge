#
#  Be sure to run `pod spec lint MSWebViewJavaScriptBridge.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "MSWebViewJavaScriptBridge"
  s.version      = "0.0.1"
  s.summary      = "Make UIWebView easy to interact with the JavaScript."
  s.homepage     = "https://github.com/MrSongzj/MSWebViewJavaScriptBridge"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "mrsong" => "424607870@qq.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/MrSongzj/MSWebViewJavaScriptBridge.git", :tag => "v0.0.1" }
  s.source_files  = "MSWebViewJavaScriptBridge/*.{h,m}"

end
