require 'rails_helper'

describe 'dummy' do
  let(:app) { controller.action(:show) }
  let(:conn) do
    Faraday.new(url: "http://#{host}/twirp") do |conn|
      conn.adapter :rack, app
    end
  end

  subject(:response) { ::Dummy::Product::ProductClient.new(conn).show(id: 'aaa') }

  describe 'not found' do
    let(:controller) do
      Class.new(Protorails::BaseController) do
        service ::Dummy::Product::ProductService
        def show
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    it 'returns twirp error: not_found' do
      expect(response.error).to have_attributes(code: :not_found)
    end
  end

  describe 'return response in callback' do
    let(:controller) do
      Class.new(Protorails::BaseController) do
        service ::Dummy::Product::ProductService
        before_action :render_unauthenticated

        def show
          {}
        end

        private

        def render_unauthenticated
          error_response(Twirp::Error.unauthenticated('unauthenticated'))
        end
      end
    end

    it 'returns twirp error: unauthenticated' do
      expect(response.error).to have_attributes(code: :unauthenticated)
    end
  end

end
