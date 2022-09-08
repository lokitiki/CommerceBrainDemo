(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using CommerceBrain

const UserApp = CommerceBrain
#port=parse(Int, ARGS[1])
CommerceBrain.main()
