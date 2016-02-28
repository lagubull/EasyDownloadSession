Pod::Spec.new do |s|

s.name         = "EasyDownloadSession"
s.version      = "1.0.2"
s.summary      = "EasyDownloadSession allows to pause and resume downloads having a full control of the order of execution."

s.homepage     = "https://github.com/lagubull/"

s.license      = {:type => 'MIT', :file => 'LICENSE.md' }

s.author       = { "Javier Laguna" => "lagubull@hotmail.com" }

s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/lagubull/EasyDownloadSession.git", :branch => "master", :tag => s.version }

s.source_files  = "EasyDownloadSession/**/*.{h,m}"
s.public_header_files = "EasyDownloadSession/**/*.{h}"

s.prefix_header_contents = '#import "EasyDownloadSession.h"'
s.requires_arc = true
end
