Pod::Spec.new do |s|
  s.name                  = 'WrappingStackLayout'
  s.version               = '0.2.0'
  s.summary               = 'WrappingStack (FlowLayout) is a SwiftUI component similar to HStack/VStack that wraps horizontally/vertically overflowing subviews onto the next lines.'
  s.homepage              = 'https://github.com/ksemianov/WrappingHStack'
  s.authors               = 'Konstantin Semianov <ksemianov>'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.swift_version         = '5'
  s.ios.deployment_target = '16.0'
  s.osx.deployment_target = '13.0'
  s.source                = { :git => 'https://github.com/ksemianov/WrappingHStack.git', :tag => s.version }
  s.source_files          = 'Sources/WrappingStack/*.swift'
end
