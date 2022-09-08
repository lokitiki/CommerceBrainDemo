module ProductsController


using JSON
using Genie.Requests
using Genie.Router
using Genie.Renderer
using Genie.Renderer.Html
using CommerceBrain.SemanticHelper
using UUIDs
using Serialization
using HTTP
using CommerceBrain.DataHelper
using CommerceBrain.AuthHelper

#remove streamsong herokuapp

  #core operational data
  struct Product
    name::String
    id::String
    description::String
    list_price::String
    caption::String
    active_price::String
    price_id::String
    currency::String
    trans_type::String
  end

  function list_products(d::Dict)
    h=d
    Product(h["name"],h["id"],h["description"],h["default_price"],h["object"],h["active_price"],h["price_id"],h["currency"],h["trans_type"])
  end

  # Build something great
  function retrieve_default_products()
    stripe_api_key = ENV["STRIPE_SECRET_KEY"]
    stripe_header="Bearer "*stripe_api_key
    r = HTTP.request("GET","https://api.stripe.com/v1/products",["Authorization"=>stripe_header,"Content-Type"=>"application/x-www-form-urlencoded"])
    j=JSON.parse(String(r.body))
    product_list=j["data"]
    #returns list of products from stripe
    return product_list
  end

  function get_rank()
    return "null"
  end

  function get_prices()
    if get_rank() != "null"
      list=get_rank()
    else
      list=retrieve_default_products()
    end
    
    #adding prices
    stripe_api_key = ENV["STRIPE_SECRET_KEY"]
    stripe_header="Bearer "*stripe_api_key
    for n in list
      productid=n["id"]
      params=Dict("query"=>"active:'true' AND product:'"*productid*"'")
      #encodedparams=HT
      r = HTTP.request("GET","https://api.stripe.com/v1/prices/search",["Authorization"=>stripe_header,"Content-Type"=>"application/x-www-form-urlencoded"],query=params)
      j=JSON.parse(String(r.body))
      res=j["data"][1]
      
      active_price=res["unit_amount_decimal"]
      currency=res["currency"]
      trans_type=res["type"]
      price_id=res["id"]
      n["active_price"]=active_price
      n["price_id"]=price_id
      n["currency"]=currency
      n["trans_type"]=trans_type
      
    end

    return list

  end

  function process()
    product_list=get_prices()
    prod_array = []
    for n in eachindex(product_list) 
      y=list_products(product_list[n])
      push!(prod_array,y)
    end
    #adding images [tbd]
    return prod_array
  end

  function browse()
    products=process()
    #set up the data
      #Product list data
    hasproductlist=ObjectProperty(:hasproductlist)
    productlistclass=SemanticClass("CommerceBrain", "ProductList")
    hasproductlistid=ObjectProperty(:hasproductlistid)
    hasproduct=ObjectProperty(:hasproduct)
    hasnextproduct=ObjectProperty(:hasnext)

    #Product data
    productclass=SemanticClass("CommerceBrain", "Product")
    #Product properties defined in product struct, will create at runtime
    graphid,individuals,assertions,viewer=set_data_context()
    haspl=ObjectProperty(:hasProductList)
    for n in eachindex(products)
      productlist=Individual("ProductList",string(uuid4()))
      push!(assertions,ClassAssertion(productlistclass,productlist))
      push!(individuals,productlist)
      push!(assertions,ObjectPropertyAssertion(viewer,haspl,productlist))
      product=Individual("Product",products[n].id)
      prodclassassert=ClassAssertion(productclass,product)
      push!(assertions,prodclassassert)
      push!(individuals,product)
      assertion1=ObjectPropertyAssertion(viewer,hasproductlist,productlist)
      push!(assertions,assertion1)
      assertion2=ObjectPropertyAssertion(productlist,hasproduct,product)
      push!(assertions,assertion2)
      if n == length(products)
        
        #do nothing
      else
        nextproduct=Individual("Product",products[n+1].id)
        prodclassassert2=ClassAssertion(productclass,nextproduct)
        push!(assertions,prodclassassert2)
        assertion3=ObjectPropertyAssertion(productlist,hasnextproduct,nextproduct)
        push!(assertions,assertion3)
      end
    end

    #define how to dispatch all this data as an ojbect to remote channel
    h=Dict("individuals"=>individuals,"assertions"=>assertions)
    DataHelper.awssink(Dict("data"=>h))

    html(:products, :product_list, products=products, context = @__MODULE__)
    
    
    end

end
