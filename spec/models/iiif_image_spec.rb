require 'rails_helper'

RSpec.describe IiifImage do
  let(:base_uri) { 'https://imageserver.example.com/cantaloupe/iiif/2/' }
  let(:identifier) { StacksIdentifier.new(druid: 'st808xq5141', file_name: 'st808xq5141_00_0001') }
  let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'full') }
  let(:instance) do
    described_class.new(base_uri: base_uri,
                        id: identifier,
                        transformation: transformation)
  end

  describe "#id" do
    subject { instance.send(:id) }
    it { is_expected.to eq 'st%2F808%2Fxq%2F5141%2Fst808xq5141_00_0001.jp2' }
  end
end