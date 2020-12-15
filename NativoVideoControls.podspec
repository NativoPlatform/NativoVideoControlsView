
Pod::Spec.new do |s|
  s.name             = 'NativoVideoControls'
  s.version          = '5.3.0'
  s.summary          = 'Video controls used by the NativoSDK. You can use this as a starting point to customize the video player for your app.'
  s.description      = 'Full screen video controls used by the NativoSDK. You can use this as a starting point to customize the video player for your app.'
  s.homepage         = 'https://github.com/NativoPlatform/NativoVideoControlsView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { "Nativo" => "sdksupport@nativo.com" }
  s.source           = { :git => 'https://github.com/NativoPlatform/NativoVideoControlsView.git', :tag => "v#{s.version}" }
  s.ios.deployment_target = '10.0'

  s.source_files = '**/*.{h,m}'
  s.resources = ['Resources.xcassets', 'NtvCustomVideoControlsView.xib']
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.dependency "NativoSDK"
end
