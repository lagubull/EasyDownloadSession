Pod::Spec.new do |s|

s.name         = "EasyDownloadSession"
s.version      = "1.0.5"
s.summary      = "EasyDownloadSession allows to pause and resume downloads having a full control of the order of execution."

s.homepage     = "https://github.com/lagubull/"

s.license      = {:type => 'MIT', :file => 'LICENSE.md' }

s.author       = { "Javier Laguna" => "lagubull@hotmail.com" }

s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/lagubull/EasyDownloadSession.git", :branch => "devSwift", :tag => s.version }

s.source_files  = "EasyDownloadSession/**/*.swift"

s.prefix_header_contents = '#import "EasyDownloadSession.h"'
s.frameworks = 'UIKit'

s.requires_arc = true

end
