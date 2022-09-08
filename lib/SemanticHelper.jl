module SemanticHelper
#so what I actually want to do is write a new small file for each request / response; then collect up those files and put them in object storage; then from object storage pull them back
#instead of sessions, make and save graphs
using NamedTupleTools
using GenieSession
using Graphs
using MetaGraphs
using OrderedCollections
using UUIDs
using Genie.Requests
using Distributed

#need to declare the session, then declare event, then declare other DataPropertyAssertion
export Individual,ObjectProperty,DataProperty,SemanticClass, ClassRelation, datastream
export ClassAssertion, ObjectPropertyAssertion, DataPropertyAssertion, SubClassOf, add_individual, add_class
export propsfromstruct, create_graph, set_data_context
#using MetaGraphs

const datastream = RemoteChannel(()->Channel(32))

struct Individual 
    namespace::String
    individual::String
end

struct ClassRelation 
  property::Symbol
end

struct ObjectProperty 
    property::Symbol
end

struct DataProperty 
    property::Symbol
end

struct SemanticClass 
    namespace::String
    classname::String
end
#= use structs for declaratory statements
function DeclareObjectProperty(namespace::String,property::Symbol)
    #edge type
end

function DeclareClass(namespace::String,property::Symbol)
    #new node
end

=#
#declear a new graph
#declare and number all individuals within graph
#create dict of number, individual, with an overall graph identifier
#dict of number, dataprop, value, with graph identifier
#tuple of source number, dest number, objectprop as key, true as value
#
function ClassAssertion(classname::SemanticClass, individual::Individual)
    return (individual,ClassRelation(:isinstanceof), classname)
end

function ObjectPropertyAssertion(subject::Individual,event::ObjectProperty,object::Individual)
    return (subject,event,object)
end

function DataPropertyAssertion(subject::Individual,property::DataProperty,predicate)
    return (subject,property,predicate)
end

function SubClassOf(childclass::SemanticClass,parentclass::SemanticClass)
    return (childclass,ClassRelation(:istypeof),parentclass)
end

#idea is you created orderedsets of all the nodes and then keep track of relationships in a list#
#then you create all the nodes from the ordered set, and create edges from all the relationships
#create ordered sets
function add_individual(namespace::String,individual::String,individuals::OrderedSet)
  push!(individuals,Individual(namespace,individual))
  return individuals
end

function add_class(namespace::String,class::String,individuals::OrderedSet)
  push!(individuals,SemanticClass(namespace,class))
  return individuals
end

#process structs
function propsfromstruct(namespace,name,structinstance)
    indiv=Individual(namespace,name)
    mynamedtuple=ntfromstruct(structinstance)
    list=[]
    for x in keys(mynamedtuple)
      #finish this
      if typeof(mynamedtuple[x]) <: Number
        prop=DataProperty(x)
        assertion=DataPropertyAssertion(indiv,prop,mynamedtuple[x])
      else
        prop=ObjectProperty(x)
        object=Individual(namespace,mynamedtuple[x])
        assertion=ObjectPropertyAssertion(indiv,prop,object)
      end
      push!(list,assertion)
    end
  return list  
end

#create a graph from this

function create_graph(graphid,individuals::OrderedSet, relations::Array)
  #make the nodes
  u=MetaGraph()
  set_prop!(u,:graphid,graphid)
  add_vertices!(u,length(individuals))
  for i in relations
    if typeof(i[3]) <: Number
      indexnum=findfirst(x->x==i[1],individuals)
      set_prop!(u,indexnum,i[2].property,i[3])
    else
      index1=findfirst(x->x==i[1],individuals)
      index2=findfirst(x->x==i[3],individuals)
      add_edge!(u,index1,index2,i[2].property,true)
    end
  end

  return u
end

function set_data_context()
  
  graphid=string(uuid4())
  individuals=OrderedSet()
  assertions=[]
  #define metadata
  #Customerdata
  customerclass=SemanticClass("CommerceBrain","Customer")
  hassession=ObjectProperty(:hasSession)
  
  #Sessiondata
  sessionclass=SemanticClass("CommerceBrain","Session")
  push!(individuals,sessionclass)
  hascustomer=ObjectProperty(:hasCustomer)
  hasview=ObjectProperty(:hasView)
  hasid=ObjectProperty(:hasId)

  #View data
  u=GenieSession.get(GenieSession.session(),:currentview)
  if isnothing(u)
    prevview=Individual("View","start")
  else
    prevview=Individual("View",string(u))
  end
  push!(individuals,prevview)
  viewclass=SemanticClass("CommerceBrain", "View")
  push!(individuals,viewclass)
  hasroute=ObjectProperty(:hasRoute)
  hasprevious=ObjectProperty(:hasPreviousView)
  hasviewtime=ObjectProperty(:hasTime)
  session=Individual("Session",GenieSession.session().id)
  push!(individuals,session)
  push!(assertions,ClassAssertion(sessionclass,session))
  viewer=Individual("View",string(uuid4()))
  GenieSession.set!(GenieSession.session(),:currentview,viewer)
  push!(assertions,ObjectPropertyAssertion(viewer,hasprevious,prevview))
  push!(individuals,viewer)
  push!(assertions,ClassAssertion(viewclass,viewer))
  push!(assertions,ObjectPropertyAssertion(session,hasview,viewer))

  return graphid,individuals,assertions,viewer
end
#=
function expand(individuals1,individuals2,assertions1,assertions2)
  for x in eachindex(individuals2)
    oldindex=x
    if findfirst(u->u==individuals2[x],individuals) !== nothing
      newindex=findfirst(u->u==x,individuals)
    else
      push!(individuals1,x)
      newindex=length(individuals1)

end

function abstract(individuals1,individuals2,assertions1,assertions2)
  

end

function joingraphs(h,g,individuals1,individuals2,assertions1,assertions2)

end
=#

end