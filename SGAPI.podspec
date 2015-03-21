Pod::Spec.new do |s|
  s.name         = "SGAPI"
  s.version      = "1.1.0"
  s.summary      = "An iOS SDK for querying the SeatGeek Platform web service."
  s.homepage     = "http://platform.seatgeek.com"
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author       = "SeatGeek"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/seatgeek/SGAPI.git", :tag => "1.1.0" }  
  s.source_files = "SGAPI/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "SGHTTPRequest", '~> 1.1.0'
end
