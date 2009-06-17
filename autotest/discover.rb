# -*- coding: utf-8 -*-
$KCODE='u'

# Autotestを実行するためのスクリプトです。
# see http://rails.aizatto.com/2007/11/19/autotest-ing-your-rails-plugin/
# $:.push(File.join(File.dirname(__FILE__), %w[.. .. rspec]))

Autotest.add_discovery do
  "rspec"
end
