Gem::Specification.new do |s|
  s.name        = 'RaaS'
  s.version     = '0.0.6'
  s.executables << 'RaaSCLI'
  s.date        = '2015-02-22'
  s.summary     = "VMware vCloud Air RaaS program"
  s.description = "A set of tools that allows VMware vCloud Air customers to interact programmatically with RaaS - Recovery as a Service"
  
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'httparty', '~> 0.12'
  s.add_runtime_dependency 'xml-fu', '~> 0.2 '
  s.add_runtime_dependency 'awesome_print', '~> 1.2'

  s.authors     = ["Massimo Re Ferrè"]
  s.email       = 'massimo@it20.info'
  s.files       = ["lib/RaaSmain.rb", "lib/modules/RaaSCore.rb"]
  s.homepage    = 'http://it20.info'
  s.license     = 'Apache License'
end
