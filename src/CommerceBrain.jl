module CommerceBrain

#include("..\\routes.jl")
#include.(filter(contains(r".jl$"), readdir("/resources"; join=true))) 

using Genie
using Genie.Router

#using AccountsController

const up = Genie.up
export up

function main()
    Genie.genie(; context = @__MODULE__)

    #Genie.config.run_as_server = true
    #Genie.config.server_host = "0.0.0.0"
    #Genie.config.server_port = port

    #println("port set to $(port)")

    #setroutes()

    #Genie.Server.up()


end




end