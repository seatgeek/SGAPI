Pod::Spec.new do |s|
  s.name         = "SGAPI"
  s.version      = "1.3.0"
  s.summary      = "An iOS SDK for querying the SeatGeek Platform web service."
  s.homepage     = "http://platform.seatgeek.com"
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author       = "SeatGeek"
  s.watchos.deployment_target = '2.0'
  s.ios.deployment_target = '7.0'
  s.source       = { :git => "https://github.com/seatgeek/SGAPI.git", :tag => "1.1.1" }
  s.source_files = "SGAPI/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "SGHTTPRequest", '>= 1.6.0'
end
