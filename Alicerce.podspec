Pod::Spec.new do |s|
    s.name          = 'Alicerce'
    s.version       = '0.2.1'
    s.license       = { :type => 'MIT', :file => 'LICENSE' }
    s.homepage      = 'https://github.com/Mindera/Alicerce.git'
    s.authors       = { 'Mindera' => 'ios@mindera.com' }
    s.summary       = 'A base for iOS Applications made with ❤️ by Mindera 🤠'
    s.description   = <<-DESC
                        Ever felt that you keep repeating yourself every time you start a new project? That you would like to have all those useful utils and helpers you love already available? We felt that way too! Thus, Alicerce was born. 🏗

                        Alicerce is a framework that aims to serve as a starting point for iOS applications, by providing the foundations for many of the common functionalities a modern application requires, as well as be a repository for those small utils and helpers that make our life easier.

                        It is designed with an MVVM architecture in mind, but you'll find most components are architecture agnostic.
                      DESC

    s.source        = { :git => 'https://github.com/Mindera/Alicerce.git', :tag => "#{s.version}" }

    s.module_name   = 'Alicerce'
    s.swift_version = '4.1'

    s.ios.deployment_target = '9.0'

    s.source_files  = [ 'Sources/**/*.swift' ]

    s.preserve_paths = [ 'install_common_crypto.sh' ]

    s.frameworks    = [ 'Foundation', 'UIKit', 'CoreData', 'Security' ]
    s.dependency 'Result', '~> 4.0'

    s.script_phase  = { :name => 'CommonCrypto', :script => '${PODS_TARGET_SRCROOT}/install_common_crypto.sh', :execution_position => :before_compile }
end
