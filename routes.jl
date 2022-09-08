using Genie.Router
using Genie.Requests
using GenieSession
using GenieSessionFileSession
using CommerceBrain.AccountsController
using CommerceBrain.ProductsController
using CommerceBrain.LearnsController
using CommerceBrain.HomepagesController
using CommerceBrain.SemanticHelper
using CommerceBrain.AuthHelper
using Distributed
using CommerceBrain.SinksController

#----------setup

#Genie.config.websockets_server = true
Genie.config.run_as_server = true

#browse routes

route("/", CommerceBrain.HomepagesController.home)

route("/browse", CommerceBrain.ProductsController.browse)


route("/learn", CommerceBrain.LearnsController.basic)

route("/about", CommerceBrain.LearnsController.about)

#account routes

route("/login", CommerceBrain.AccountsController.login, named=:show_login)

route("/callback") do
    CommerceBrain.AccountsController.callback(Genie.Requests.getpayload(:code))
end

route("/welcomeback", CommerceBrain.HomepagesController.returninghome)

route("/myaccount", CommerceBrain.AccountsController.myaccount)

route("/logout", CommerceBrain.AccountsController.logout)

#checkout routes

route("/checkout", method=POST) do
    CommerceBrain.CheckoutsController.create_checkout_session(postpayload(:priceId))
end

route("/success") do
    CommerceBrain.CheckoutsController.success(getpayload(:session_id))
end

route("/cancelled", CommerceBrain.CheckoutsController.cancelled)

#data routes

route("/stagegraph", CommerceBrain.SinksController.stagegraph)