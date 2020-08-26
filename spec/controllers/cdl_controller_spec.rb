# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlController do
  let(:user) { User.new id: 'username', jwt_tokens: [token] }
  let(:token) { JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm) }
  let(:payload) { { aud: 'druid', sub: 'username', exp: (Time.zone.now + 1.day).to_i } }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    cookies.encrypted[:tokens] = [token]
  end

  describe '#show' do
    context 'without a token' do
      it 'is a 404' do
        get :show, { params: { id: 'other-druid' } }

        expect(response.status).to eq 400
      end
    end

    it 'renders some information from the token' do
      get :show, { params: { id: 'druid' } }

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).with_indifferent_access).to include(
        sub: 'username', aud: 'druid', exp: a_kind_of(Numeric)
      )
    end
  end

  describe '#create' do
    let(:barcoded_item_xml) do
      <<-EOXML
        <publicObject>
          <identityMetadata>
            <sourceId source="sul">36105110268922</sourceId>
          </identityMetadata>
        </publicObject>
      EOXML
    end

    let(:non_barcoded_item_xml) do
      <<-EOXML
        <publicObject>
          <identityMetadata>
            <sourceId source="sul">this is not a barcode</sourceId>
          </identityMetadata>
        </publicObject>
      EOXML
    end

    context 'with a token' do
      it 'stores the token in a cookie' do
        get :create, { params: { id: 'other-druid', token: 'xyz' } }

        expect(cookies.encrypted[:tokens].length).to eq 2
      end
    end

    it 'bounces you to requests to handle the symphony interaction' do
      allow(Purl).to receive(:public_xml).with('other-druid').and_return(barcoded_item_xml)

      get :create, { params: { id: 'other-druid' } }

      expect(response).to redirect_to('https://requests.stanford.edu/cdl/checkout?barcode=36105110268922&id=other-druid&return_to=http%3A%2F%2Ftest.host%2Fauth%2Fiiif%2Fcdl%2Fother-druid%2Fcheckout')
    end

    context 'with a record without a barcode' do
      it 'is a 400' do
        allow(Purl).to receive(:public_xml).with('other-druid').and_return(non_barcoded_item_xml)
        get :create, { params: { id: 'other-druid' } }

        expect(response.status).to eq 400
      end
    end
  end

  describe '#delete' do
    context 'with a success parameter' do
      it 'purges the cookie' do
        get :delete, params: { id: 'druid', success: true }

        expect(cookies.encrypted[:tokens].length).to eq 0
      end
    end

    it 'bounces you to requests to handle the symphony interaction' do
      get :delete, params: { id: 'druid' }

      url = 'http%3A%2F%2Ftest.host%2Fauth%2Fiiif%2Fcdl%2Fdruid%2Fcheckin'
      expect(response).to redirect_to("https://requests.stanford.edu/cdl/checkin?return_to=#{url}&token=#{token}")
    end
  end
end