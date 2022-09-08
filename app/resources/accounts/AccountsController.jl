module AccountsController
  using Genie.Router
  using Genie.Requests
  using Genie.Renderer
  using Genie.Renderer.Html
  using GenieSession
  using JSON
  using JWTs
  using OpenIDConnect
  using CommerceBrain.AuthHelper
  using HTTP

  
  oidc_config = Dict("issuer"=> ENV["AUTHZERO_ISSUER"],
  "authority"=>ENV["AUTHZERO_ISSUER"]*".well-known/openid-configuration",
  "client_id"=>ENV["AUTHZERO_CLIENTID"],
  "client_secret"=>ENV["AUTHZERO_SECRET"],
  "token_endpoint"=>ENV["AUTHZERO_ISSUER"]*"oauth/token",
  "authorization_endpoint"=>ENV["AUTHZERO_ISSUER"]*"authorize",
  "do_refresh"=>true)

  oidcctx = OpenIDConnect.OIDCCtx(oidc_config["issuer"], ENV["SITE_NAME"]*"/callback", String(oidc_config["client_id"]), String(oidc_config["client_secret"]), ["openid", "email", "profile", "offline_access"])

  function login()
    uri=flow_request_authorization_code(oidcctx)
    redirect(uri)
  end

  function callback(code)
    ac=flow_get_token(oidcctx,code)
    keyset = JWTs.JWKSet(ENV["AUTHZERO_ISSUER"]*".well-known/jwks.json")
    JWTs.refresh!(keyset)

    keyid = first(first(keyset.keys))

    jwt=JWTs.JWT(;jwt=ac["id_token"])
    validation = JWTs.validate!(jwt, keyset,keyid)
    
    cl=JWTs.claims(jwt)
    AuthHelper.authenticate(cl["sub"],GenieSession.session(params()))
    sesh=GenieSession.session()
    authsessionkey=ENV["SITE_NAME"]*"/sid"
    GenieSession.set!(sesh,:sid,cl[authsessionkey])
    GenieSession.set!(GenieSession.session(),:JWT,jwt)
    redirect("/welcomeback")
  end

  function myaccount()
    authenticated() || redirect("/")
    stripe_api_key = ENV["STRIPE_SECRET_KEY"]
    sessionapi=Dict("checkout_sessions"=>"https://api.stripe.com/v1/checkout/sessions","billing_portal"=>"https://api.stripe.com/v1/billing_portal/sessions")
    stripe_header="Bearer "*stripe_api_key
    params=Dict("customer"=>GenieSession.get(GenieSession.session(),:sid),"return_url"=>ENV["SITE_NAME"]*"/myaccount")
    r=HTTP.request("POST",sessionapi["billing_portal"],["Authorization"=>stripe_header,"Content-Type"=>"application/x-www-form-urlencoded"],HTTP.URIs.escapeuri(params))
    s=String(r.body)
    u=JSON.parse(s)
    redirect(u["url"])
    thing=claims(GenieSession.get(GenieSession.session(),:JWT))
    "<div class='container-fluid'>
    <p>"*string(thing)*"</p></br>
    <a href="*u["url"]*">Click to manage subscriptions</a>
    </div>"
  end

  function logout()
    AuthHelper.deauthenticate(GenieSession.session(params()))
    redirectparams = Dict("returnTo"=> ENV["SITE_NAME"], "client_id"=> oidc_config["client_id"])
    encodedparams=HTTP.URIs.escapeuri(redirectparams)
    r = HTTP.request("GET", oidc_config["issuer"]*"v2/logout?"*encodedparams; verbose=3)
  end

end
