require File.join(File.dirname(__FILE__), 'test_helper')
Test::Unit::AutoRunner.run(true, File.dirname(__FILE__), ['--pattern=/.*?_test\.rb\Z/'])
