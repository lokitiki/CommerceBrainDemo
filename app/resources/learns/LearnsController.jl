module LearnsController

using GraphQLClient
import Genie.Router
using Genie.Renderer
using Genie.Renderer.Html
using HTTP
using CommerceBrain.AuthHelper

struct BasicPost
  title::String
  slug::String
  subtitle::String
  content::String
end

function basic()
  client = GraphQLClient.Client(ENV["HYGRAPH_LINK"])
  gql_query="""query MyQuery {
        demoModels {
          content {
            html
          }
          slug
          stage
          subtitle
          title
        }
      }"""

  response = GraphQLClient.execute(client,gql_query)

  content= String(response.data["demoModels"][1]["content"]["html"])
  title = String(response.data["demoModels"][1]["title"])
  slug = String(response.data["demoModels"][1]["slug"])
  subtitle = String(response.data["demoModels"][1]["subtitle"])

  basic=BasicPost(title,slug,subtitle,content)

  html(:learns,:learn,basic=basic, context = @__MODULE__)
end

function about()
  client = GraphQLClient.Client(ENV["HYGRAPH_LINK"])
  gql_query="""query MyQuery {
        demoModels {
          content {
            html
          }
          slug
          stage
          subtitle
          title
        }
      }"""

  response = GraphQLClient.execute(client,gql_query)

  content= String(response.data["demoModels"][2]["content"]["html"])
  title = String(response.data["demoModels"][2]["title"])
  slug = String(response.data["demoModels"][2]["slug"])
  subtitle = String(response.data["demoModels"][2]["subtitle"])

  basic=BasicPost(title,slug,subtitle,content)

  html(:learns,:learn,basic=basic,context = @__MODULE__)
end

end



