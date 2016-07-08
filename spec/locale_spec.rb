# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SchemaComments::SchemaComment do

  before(:each) do
    SchemaComments.yaml_path = File.expand_path('../locale_spec.yml', __FILE__)
  end

  describe :model_comments do
    let(:result) do
      {
        'address' => '住所',
        'email'   => 'メール',
        'person'  => '人',
      }
    end
    it{ expect(SchemaComments::SchemaComment.model_comments).to eq result }
  end

  describe :attribute_comments do
    let(:result) do
      {
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
        'person' => {
          'name' => '名前',
          'id'   => '人',
        }
      }
    end
    it{ expect(SchemaComments::SchemaComment.attribute_comments).to eq result }
  end
end
