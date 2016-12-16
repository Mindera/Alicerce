Pod::Spec.new do |s|
  s.name         = "Alicerce"
  s.version      = "0.1"
  s.summary      = "A base for iOS Applications with ❤️ from Mindera 🤠"
  s.description  = <<-DESC
    A iOS Kit with powerful tools 🎉
  DESC
  s.homepage     = "https://github.com/Mindera/Alicerce.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Mindera" => "ios@mindera.com" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/Mindera/Alicerce.git", :branch => "master" }
  s.source_files  = "Alicerce/Sources/**/*"
  s.frameworks  = [ "Foundation", "UIKit" ]
end
