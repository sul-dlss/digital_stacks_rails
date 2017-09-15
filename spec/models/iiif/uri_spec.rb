# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Iiif::URI do
  describe '#to_s' do
    subject { instance.to_s }
    let(:base_uri) { 'https://imageserver.example.com/cantaloupe/iiif/2/' }
    let(:identifier) { 'st%252F808%252Fxq%252F5141%252Fst808xq5141_00_0001.jp2' }
    let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'full') }

    context "with a transformation" do
      let(:instance) do
        described_class.new(base_uri: base_uri,
                            identifier: identifier,
                            transformation: transformation)
      end
      it do
        is_expected.to eq 'https://imageserver.example.com/cantaloupe/iiif/2/'\
        'st%2F808%2Fxq%2F5141%2Fst808xq5141_00_0001.jp2/full/full/0/default.jpg'
      end
    end

    context "without a transformation" do
      let(:instance) do
        described_class.new(base_uri: base_uri,
                            identifier: identifier)
      end
      it do
        is_expected.to eq 'https://imageserver.example.com/cantaloupe/iiif/2/' \
        'st%252F808%252Fxq%252F5141%252Fst808xq5141_00_0001.jp2/info.json'
      end
    end
  end
end