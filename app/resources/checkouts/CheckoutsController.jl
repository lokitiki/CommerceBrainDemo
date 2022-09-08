module CheckoutsController
  using HTTP
  using Genie.Requests
  using Genie.Router
  using Genie.Renderer
  using GenieSession
  using JSON
  using CommerceBrain.AuthHelper
  strpe_api_version = "2020-08-27"
  stripe_api_key = ENV["STRIPE_SECRET_KEY"]
  checkout_apis=Dict("checkout_sessions"=>"https://api.stripe.com/v1/checkout/sessions","billing_portal"=>"https://api.stripe.com/v1/billing_portal/sessions")
  stripe_header="Bearer "*stripe_api_key
  
  domain_url=ENV["SITE_NAME"]

  function get_sid()
    sesh=GenieSession.session()
    sid=GenieSession.get(sesh,:sid)
    return sid
  end

  function create_checkout_session(price)
    line_items=Dict("price"=> price,"quantity"=>1)
    params=Dict("success_url"=>domain_url*"/success?session_id={CHECKOUT_SESSION_ID}",
    "cancel_url"=>domain_url*"/cancelled",
    "payment_method_types[0]"=>"card",
    "mode"=>"subscription",
    "line_items[0][price]"=>line_items["price"],
    "line_items[0][quantity]"=>line_items["quantity"])
    if AuthHelper.is_authenticated(GenieSession.session())
        stripe_id=get_sid()
        params["customer"]=stripe_id
    end

    r=HTTP.request("POST",checkout_apis["checkout_sessions"],["Authorization"=>stripe_header,"Content-Type"=>"application/x-www-form-urlencoded"],HTTP.URIs.escapeuri(params))
    s=String(r.body)
    u=JSON.parse(s)
    return redirect(u["url"])
end

function webhook()
  
    webhook_secret=ENV["STRIPE_WEBHOOK_SECRET"]
    request_data=postpayload()

    if webhook_secret
        signature=request_data["Stripe-Signature"]
        try
            data=request_data["data"]
            event_type=request_data["type"]
        catch
            return "Something went wrong"
        end
        event_type = event["type"]
    else
        data=request_data["data"]
        event_type=request_data["type"]
    end
    data_object=data["object"]
    if event_type == "checkout.session.completed"
        println("success")
        return JSON.json(Dict("status" => "success"))
    else
        "Unhandled_event"
    end
end

function cancelled()
    "You cancelled your transaction"
    sleep(3)
    redirect("/")
    
end

function success(sess_id)
    "<div class=container-fluid><p>Your transaction number is "*sess_id*"</p></br><a href="*ENV["SITE_NAME"]*">Go Home</a>"
end 

end
