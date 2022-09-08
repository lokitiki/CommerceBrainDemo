module DataHelper
using AWS
using AWS: @service
using JSONWebTokens
using Dates
using JSON
using HTTP
using Dates
using UUIDs
using BSON
using Serialization
@service S3

function awssink(payload)
    #io = IOBuffer()
    #serialize(io, payload)
    aws = global_aws_config(creds = AWSCredentials(ENV["AWS_ACCESS_KEY_ID"],ENV["AWS_SECRET_KEY"]), region = "us-east-1")
    current_date=string(Dates.today())
    object_name=string(uuid4())
    #name=tempname()
    b=IOBuffer()
    bson(b,payload)
    S3.put_object(String(ENV["bucketname"]),current_date*"/"*object_name,Dict("body"=>take!(b)))
    
end

end