Pod::Spec.new do |s|
  s.name         = "ZXGSqliteCache"
  s.version      = "1.0.0"
  s.ios.deployment_target = '8.0'
  s.summary      = "A fast and convenient sqlite cache"
  s.homepage     = "https://github.com/onzxgway/ZXGSqliteCache"
  s.license      = "MIT"
  s.author       = { "onzxgway" => "1508377021@qq.com" }
  s.source       = { :git => "https://github.com/onzxgway/ZXGSqliteCache.git", :tag => s.version }
  s.source_files  = "ZXGSqliteCache"
  s.requires_arc = true
  s.libraries    = "sqlite3"   
end