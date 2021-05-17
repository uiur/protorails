require 'rails_helper'

describe ::Dummy::Product::ProductService, type: :request do
  let(:params) { {} }

  def conn
    Faraday.new(url: "http://#{host}/twirp") do |conn|
      conn.adapter :rack, app
    end
  end

  describe '#show' do
    subject(:response) { ::Dummy::Product::ProductClient.new(conn).show(id: 'foo') }

    it 'returns data' do
      expect(response.error).to eq(nil)
      expect(response.data).to be_present
    end
  end
end
