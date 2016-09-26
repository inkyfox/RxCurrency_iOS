platform :ios, '9.0'

use_frameworks!

#source 'https://github.com/CocoaPods/Specs.git'

def pods
    pod 'SwiftyJSON', '~> 3.0'
    pod 'RxSwift',    '~> 3.0.0-beta.1'
    pod 'RxCocoa',    '~> 3.0.0-beta.1'
    pod 'RxDataSources',    '~> 1.0.0-beta.2'
    pod 'RxAlamofire',    '~> 3.0.0-beta.1'
end

target 'CurrencyConverter' do
    pods
end

target 'CurrencyConverterTests' do
    pods
    pod 'RxTests',    '~> 3.0.0-beta.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
