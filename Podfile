platform :ios, '13.0'

workspace 'MoveSDKSample'
use_frameworks!

target 'MoveSDKSample' do

	pod 'AlertToast'

	# Dolphin Pods
	pod 'DolphinMoveSDK', '~> 2.6.7'

end

### The following may be necessary in Xcode 11 or below for compilation for the Simulator

#post_install do |installer|
#	installer.pods_project.targets.each do |target|
#		target.build_configurations.each do |config|
#			config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
#		end
#	end
#end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings.delete "IPHONEOS_DEPLOYMENT_TARGET"
		end
	end
end
