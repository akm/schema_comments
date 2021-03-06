# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SchemaComments::SchemaComment do

  before(:each) do
    SchemaComments.yaml_path = File.expand_path('../locale_spec/schema_comments.yml', __FILE__)
  end

  describe :model_comments do
    let(:result) do
      {
        'person'  => '人',
        'address' => '住所',
        'email'   => 'メール',
      }
    end
    it{ expect(SchemaComments::SchemaComment.model_comments).to eq result }
  end

  describe :attribute_comments do
    let(:result) do
      {
        'person' => {
          'name' => '名前',
          'id'   => '人',
        },
        'address' => {
          'person' => '人',
          'person_id' => '人ID',
          'descriptions' => '記述',
          'id' => '住所',
        },
        'email' => {
          'person' => '人',
          'person_id' => '人ID',
          'address'   => 'アドレス',
          'id' => 'メール',
        },
      }
    end
    it{ expect(SchemaComments::SchemaComment.attribute_comments).to eq result }
  end

  describe :locale_yaml do
    let(:result) do
      File.read(File.expand_path("../locale_spec/ja.yml", __FILE__)).tap do |r|
        r.gsub!('"', '') if Gem::Version.new(YAML::VERSION) >= Gem::Version.new("2.0.17")
      end
    end
    it{ expect(SchemaComments::SchemaComment.locale_yaml(:ja)).to eq result }
  end
end
