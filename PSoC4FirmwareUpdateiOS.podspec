#
# Be sure to run `pod lib lint PSoC4FirmwareUpdateiOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PSoC4FirmwareUpdateiOS'
  s.version          = '0.2.0'
  s.summary          = 'Bootloader based firmware update library for PSoC4 BLE (4200)'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Bootloader based firmware update library for PSoC4 BLE (4200), The example app has a bluetooth version of the firmware updater. The sample project used for the updater is at https://github.com/perusworld/PSoC4OTAUpdate
                       DESC

  s.homepage         = 'https://github.com/perusworld/PSoC4FirmwareUpdateiOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Saravana Perumal Shanmugam' => 'saravanaperumal@msn.com' }
  s.source           = { :git => 'https://github.com/perusworld/PSoC4FirmwareUpdateiOS.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/perusworld'

  s.ios.deployment_target = '8.0'

  s.source_files = 'PSoC4FirmwareUpdateiOS/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PSoC4FirmwareUpdateiOS' => ['PSoC4FirmwareUpdateiOS/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
