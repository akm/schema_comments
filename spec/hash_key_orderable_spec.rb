require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'hash_key_orderable'

describe HashKeyOrderable do

  describe :each do
    it "should each with key order" do
      hash = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}
      hash.extend(HashKeyOrderable)
      hash.key_order = %w(b d c a)
      actuals = []
      hash.each do |key, value|
        actuals << key
      end
      actuals.should == hash.key_order
    end

    it "should use original each without key_order" do
      hash = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}
      hash.extend(HashKeyOrderable)
      hash.should_receive(:each_without_key_order) # original each method
      hash.each{ }
    end

    it "should appear remain key after key_order in each" do
      hash = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5}
      hash.extend(HashKeyOrderable)
      hash.key_order = %w(b e d)
      actuals = []
      hash.each do |key, value|
        actuals << key
      end
      actuals[0..2].should == hash.key_order
      actuals[3..4].sort.should == %w(a c)
    end

    it "should ignore unexist key in key_order" do
      hash = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5}
      hash.extend(HashKeyOrderable)
      hash.key_order = %w(b z x d)
      actuals = []
      hash.each do |key, value|
        actuals << key
      end
      actuals[0..1].should == %w(b d)
      actuals[2..4].sort.should == %w(a c e)
    end

  end
end   
