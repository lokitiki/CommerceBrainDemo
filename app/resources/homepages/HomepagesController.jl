module HomepagesController
using Genie.Router
using Genie.Renderer
using Genie.Renderer.Html
using CommerceBrain.AuthHelper

function home()
    html(:homepages,:homepage, context = @__MODULE__)
end

function returninghome()
    html(:homepages,:homepage,context = @__MODULE__)
end

end