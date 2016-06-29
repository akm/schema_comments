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
      expect(actuals).to eq hash.key_order
    end

    it "should use original each without key_order" do
      hash = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}
      hash.extend(HashKeyOrderable)
      expect(hash).to receive(:each_without_key_order) # original each method
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
      expect(actuals[0..2]).to eq hash.key_order
      expect(actuals[3..4].sort).to eq %w(a c)
    end

    it "should ignore unexist key in key_order" do
      hash = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5}
      hash.extend(HashKeyOrderable)
      hash.key_order = %w(b z x d)
      actuals = []
      hash.each do |key, value|
        actuals << key
      end
      expect(actuals[0..1]).to eq %w(b d)
      expect(actuals[2..4].sort).to eq %w(a c e)
    end

  end
end
