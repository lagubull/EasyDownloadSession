Pod::Spec.new do |s|

s.name         = "EasyDownloadSession"
s.version      = "1.0.0"
s.summary      = "SimpleTableView is an easy way of using a tableView connected to CoreData via a NSFetchedResultsController with pagination capabilities."

s.homepage     = "https://github.com/lagubull/"

s.license      = {:type => 'MIT', :file => 'LICENSE.md' }

s.author       = { "Javier Laguna" => "lagubull@hotmail.com" }

s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/lagubull/EasyDownloadSession.git", :branch => "master", :tag => s.version }

s.source_files  = "EasyDownloadSession/**/*.{h,m}"
s.public_header_files = "EasyDownloadSession/**/*.{h}"

s.requires_arc = true
end
