Gem::Specification.new do |s|
  s.name = 'exception_notification'
  s.version = '2.5.2'
  s.authors = ["Jamis Buck", "Josh Peek"]
  s.date = %q{2011-08-29}
  s.summary = "Exception notification by email for Rails apps"
  s.email = "smartinez87@gmail.com"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test`.split("\n")
  s.require_path = 'lib'

  s.add_development_dependency "rails", ">= 3.0.4"
end
