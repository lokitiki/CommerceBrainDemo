module AuthHelper


"""
Functionality for authenticating Genie users.
"""

using Genie
using GenieSession
using GenieSessionFileSession

export authenticate, deauthenticate, is_authenticated, get_authentication, authenticated
export login, logout, with_authentication, without_authentication, @authenticated!

const USER_ID_KEY = :__auth_user_id


"""
Stores the user id on the session.
"""
function authenticate(user_id::Any, session::GenieSession.Session) :: GenieSession.Session
  GenieSession.set!(session, USER_ID_KEY, user_id)
end
#function authenticate(user_id::String, session::GenieSession.Session)
#  authenticate(Int(user_id, session)
#end
#function authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any} = Genie.Requests.payload()) :: GenieSession.Session
#  authenticate(user_id, params[:SESSION])
#end


"""
    deauthenticate(session) :: Sessions.Session
    deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session
Removes the user id from the session.
"""
function deauthenticate(session::GenieSession.Session) :: GenieSession.Session
  GenieSession.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict = Genie.Requests.payload()) :: GenieSession.Session
  deauthenticate(params[:SESSION])
end


"""
    is_authenticated(session) :: Bool
    is_authenticated(params::Dict{Symbol,Any}) :: Bool
Returns `true` if a user id is stored on the session.
"""
function is_authenticated(session::Union{GenieSession.Session,Nothing}) :: Bool
  GenieSession.isset(session, USER_ID_KEY)
end
function is_authenticated(params::Dict = Genie.Requests.payload()) :: Bool
  is_authenticated(params[:SESSION])
end

const authenticated = is_authenticated


"""
    @authenticate!(exception::E = ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
If the current request is not authenticated it throws an ExceptionalResponse exception.
"""
macro authenticated!(exception = Genie.Exceptions.ExceptionalResponse(Genie.Renderer.redirect(:show_login)))
  :(AuthHelper.authenticated() || throw($exception))
end


"""
    get_authentication(session) :: Union{Nothing,Any}
    get_authentication(params::Dict{Symbol,Any}) :: Union{Nothing,Any}
Returns the user id stored on the session, if available.
"""
function get_authentication(session::GenieSession.Session) :: Union{Nothing,Any}
  GenieSession.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict = Genie.Requests.payload()) :: Union{Nothing,Any}
  get_authentication(params[:SESSION])
end

const authentication = get_authentication


"""
    login(user, session) :: Union{Nothing,GenieSession.Session}
    login(user, params::Dict{Symbol,Any}) :: Union{Nothing,GenieSession.Session}
Persists on session the id of the user object and returns the session.
"""
#function login(user::M, session::GenieSession.Session)::Union{Nothing,GenieSession.Session} where {M<:SearchLight.AbstractModel}
#  authenticate(getfield(user, Symbol(pk(user))), session)
#end
#function login(user::M, params::Dict = Genie.Requests.payload())::Union{Nothing,GenieSession.Session} where {M<:SearchLight.AbstractModel}
#  login(user, params[:SESSION])
#end


"""
    logout(session) :: Sessions.Session
    logout(params::Dict{Symbol,Any}) :: Sessions.Session
Deletes the id of the user object from the session, effectively logging the user off.
"""
function logout(session::GenieSession.Session) :: GenieSession.Session
  deauthenticate(session)
end
function logout(params::Dict = Genie.Requests.payload()) :: GenieSession.Session
  logout(params[:SESSION])
end


"""
    with_authentication(f::Function, fallback::Function, session)
    with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.
"""
function with_authentication(f::Function, fallback::Function, session::Union{GenieSession.Session,Nothing})
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict = Genie.Requests.payload())
  with_authentication(f, fallback, params[:SESSION])
end


"""
    without_authentication(f::Function, session)
    without_authentication(f::Function, params::Dict{Symbol,Any})
Invokes `f` if there is no user authenticated on the current session.
"""
function without_authentication(f::Function, session::GenieSession.Session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict = Genie.Requests.payload())
  without_authentication(f, params[:SESSION])
end

end # module
