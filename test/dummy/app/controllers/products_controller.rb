class ProductsController < ApplicationController
  service ::Dummy::Product::ProductService

  def show
    { id: 'foo', name: 'product foo', price: 100 }
  end
end
