class ProductsController < ApplicationController
  before_action :validate_search_key, only: [:search]
  before_action :authenticate_user!, only: [:favorite]
  before_action :find_product, only: [:show, :add_to_cart, :favorite, :upvote, :add_buying_quantity, :remove_buying_quantity]
  before_action :get_products, only: [:index, :add_to_cart, :favorite]
  respond_to :js

  def index
  end
  def show
    @photos = @product.photos.all
    @posts = @product.posts.includes(:graphics).includes(:user)
    @prints = @product.prints.all
    if @posts.blank?
      @avg_post = 0
      @avg_look = 0
      @avg_price = 0
    else
      @avg_post = @posts.average(:rating).round(2)
      @avg_look = @posts.average(:look).round(2)
      @avg_price = @posts.average(:price).round(2)
    end
  end
  def search
		@products = Product.ransack({:title_cont => @q}).result(:distinct => true)
	end
  def add_to_cart

    if !current_cart.products.include?(@product)
      current_cart.add_product_to_cart(@product)
      @product.quantity -= @product.buying_quantity
      @product.buying_quantity = 1
      @product.save
    else
      # flash[:warning] = "不能重复加入商品"
      # redirect_to :back
    end
    respond_to do |format|
      format.js   { render :layout => false }
    end
  end

  def add_buying_quantity
    if @product.buying_quantity <= @product.quantity
      @product.buying_quantity +=1
      @product.save
      # redirect_to :back
      respond_to do |format|
        format.js   { render :layout => false }
      end
    end
  end

  def remove_buying_quantity
    if @product.buying_quantity > 1
      @product.buying_quantity -= 1
      @product.save
      # redirect_to :back
      respond_to do |format|
        format.js   { render :layout => false }
      end
    end
  end
  def favorite

    type = params[:type]
    if type == "favorite"
    current_user.favorite_products << @product
    redirect_to :back
    elsif type == "unfavorite"
    current_user.favorite_products.delete(@product)
    redirect_to :back

    else
    redirect_to :back
    end
  end

  def upvote
    @product.votes.create
    @product.like = @product.votes.count
    @product.save
    redirect_to :back
  end
  protected

  def find_product
    @product = Product.find(params[:id])
  end
  def validate_search_key
    @q = params[:query_string].gsub(/\|\'|\/|\?/, "") if params[:query_string].present?
  end
end
