module HashKeyOrderable
  attr_accessor :key_order
  
  def each_with_key_order(&block)
    if @key_order.nil? || @key_order.empty?
      each_without_key_order(&block)
      return self
    end
    unexist_keys = @key_order - self.keys
    actual_order = (@key_order - unexist_keys) | self.keys
    actual_order.each do |key|
      yield(key, self[key])
    end
    self
  end

  def self.extended(obj)
    obj.instance_eval do
      alias :each_without_key_order :each
      alias :each :each_with_key_order
    end
  end
end
