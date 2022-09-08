module SinksController

using HTTP
using JSON
using Dates
using JSONWebTokens
using BSON
using AWS
using OrderedCollections
using AWS: @service
@service S3

function getalls3objects(bucketname)
  objectlist=[]
  r=S3.list_objects_v2(bucketname)
  
  
  for a in r["Contents"]
    push!(objectlist,a["Key"])
  end
  while r["IsTruncated"]=="true"
    params=Dict("ContinuationToken"=>r["NextContinuationToken"])
    r=S3.list_objects_v2(bucketname,params)
    for a in r["Contents"]
      push!(objectlist,a["Key"])
    end
  end
  return objectlist
end

function stagegraph()
  #startdate=graphreq["start_date"]
  #enddate=graphreq["end_date"]
  aws = global_aws_config(creds = AWSCredentials(ENV["AWS_ACCESS_KEY_ID"],ENV["AWS_SECRET_KEY"]), region = "us-east-1")
  q=getalls3objects(ENV["bucketname"])
  for x in q
    bs=S3.get_object(ENV["bucketname"],x)
    print(IOBuffer(bs))
    
    p=BSON.load(IOBuffer(bs))
    print(p)
  end
end

function graphquery(analyticsreq)
  #nothing
end

end
