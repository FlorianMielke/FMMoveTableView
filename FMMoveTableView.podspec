Pod::Spec.new do |s|
  s.name     = 'FMMoveTableView'
  s.version  = '2.0.1'
  s.license  = 'MIT'
  s.summary  = 'FMMoveTable is an UITableView subclass that provides moving rows by simply tap and hold.'
  s.homepage = 'https://github.com/FlorianMielke/FMMoveTableView'
  s.author   = 'Florian Mielke'
  s.source   = { :git => 'https://github.com/unteleported/FMMoveTableView.git', :tag => "v#{s.version.to_s}" }
  s.platform = :ios
  s.source_files = 'FMFramework/*.{h,m}'
  s.frameworks   = 'QuartzCore'
  s.requires_arc = true
end
