platform :ios, '9.0'

use_frameworks!

#source 'https://github.com/CocoaPods/Specs.git'

def pods
    pod 'SwiftyJSON', '~> 3.1'
    pod 'RxSwift',    '~> 3.2'
    pod 'RxCocoa',    '~> 3.2'
    pod 'RxDataSources',    '~> 1.0'
    pod 'RxAlamofire',    '~> 3.0'
end

target 'CurrencyConverter' do
    pods
    pod 'Firebase/Crash'
    pod 'Firebase/Core'
    pod 'Firebase/AdMob'
end

target 'CurrencyConverterTests' do
    pods
    pod 'RxTest',    '~> 3.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
