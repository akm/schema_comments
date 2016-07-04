unless Gem.loaded_specs['rails'].version >= Gem::Version.new('5.0.0')
  ActiveRecord::Migration.instance_eval(<<-EOS, __FILE__, __LINE__ + 1)
    def [](*arg)
      self
    end
  EOS
end
