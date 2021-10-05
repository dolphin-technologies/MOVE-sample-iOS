platform :ios, '13.0'

workspace 'MoveSDKSample'
use_frameworks!

target 'MoveSDKSample' do

	# for requests
	pod 'Alamofire', '~> 5'

	pod 'AlertToast'

	#	Dolphin Pods
	pod 'DolphinMoveSDK'

end

### The following may be necesssary in Xcode 11 or bellow for compilation for the Simulator

#post_install do |installer|
#	installer.pods_project.targets.each do |target|
#		target.build_configurations.each do |config|
#			config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
#		end
#	end
#end
