Pod::Spec.new do |s|
    s.name          = 'Alicerce'
    s.version       = '0.14.0'
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
    s.swift_version = '5.5'

    s.ios.deployment_target = '10.0'

    s.subspec 'Core' do |ss|
        ss.source_files = 'Sources/{Utils,Shared}/**/*.swift'
        ss.dependency 'Alicerce/Extensions/Foundation'
    end

    s.subspec 'Analytics' do |ss|
        ss.source_files = 'Sources/Analytics/**/*.swift'
        ss.dependency 'Alicerce/Core'
    end

    s.subspec 'AutoLayout' do |ss|
        ss.source_files = 'Sources/AutoLayout/*.swift'
        ss.dependency 'Alicerce/Extensions/UIKit'
        ss.frameworks   = 'UIKit'
    end

    s.subspec 'DeepLinking' do |ss|
        ss.source_files = 'Sources/DeepLinking/**/*.swift'
        ss.dependency 'Alicerce/Core'
        ss.frameworks   = 'UIKit'
    end

    s.subspec 'Extensions' do |ss|

        ss.subspec 'Foundation' do |sss|
            sss.source_files = 'Sources/Extensions/Foundation/*.{swift,h,m}'
            sss.frameworks   = 'Foundation'
        end

        ss.subspec 'UIKit' do |sss|
            sss.source_files = 'Sources/Extensions/UIKit/*.{swift,h,m}'
            sss.frameworks   = 'UIKit'
        end
    end

    s.subspec 'Logging' do |ss|
        ss.source_files = 'Sources/Logging/**/*.swift'
        ss.dependency 'Alicerce/Core'
    end

    s.subspec 'Network' do |ss|
        ss.source_files = 'Sources/Network/**/*.swift'
        ss.dependency 'Alicerce/Core'
        ss.frameworks   = 'Security'
    end

    s.subspec 'Observers' do |ss|
        ss.source_files = 'Sources/Observers/**/*.swift'
        ss.frameworks   =  'UIKit'
    end

    s.subspec 'PerformanceMetrics' do |ss|
        ss.source_files = 'Sources/PerformanceMetrics/**/*.swift'
        ss.dependency 'Alicerce/Core'
    end

    s.subspec 'Persistence' do |ss|
        ss.source_files = 'Sources/Persistence/*.swift'
        ss.dependency 'Alicerce/Core'
        ss.dependency 'Alicerce/Logging'
        ss.dependency 'Alicerce/PerformanceMetrics'

        ss.subspec 'CoreData' do |sss|
            sss.source_files = 'Sources/Persistence/CoreData/*.{swift,h,m}'
            sss.frameworks   = 'CoreData'
        end
    end

    s.subspec 'StackOrchestrator' do |ss|
        ss.source_files = 'Sources/StackOrchestrator/**/*.swift'
        ss.dependency 'Alicerce/Core'
        ss.dependency 'Alicerce/Logging'
        ss.dependency 'Alicerce/Network'
        ss.dependency 'Alicerce/Persistence'
        ss.dependency 'Alicerce/PerformanceMetrics'
    end

    s.subspec 'View' do |ss|
        ss.source_files = 'Sources/View/**/*.swift'
        ss.dependency 'Alicerce/Core'
        ss.frameworks   = 'UIKit'
    end
end
