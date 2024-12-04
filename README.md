<img src="https://github.com/lxmota/Norma.jl/blob/main/doc/norma-contact-1.png" width="300">
<img src="https://github.com/lxmota/Norma.jl/blob/main/doc/norma-contact-2.png" width="300">

# Norma
A Julia prototype for testing algorithms and ideas for coupling and multiphysics mainly in solid mechanics and heat conduction.

Steps to clone and install.

Clone the repository:

    cd /some_path
    git clone -v git@github.com:lxmota/Norma.jl.git
    cd Norma.jl
    julia

To install within the package manager (press `]` in the Julia REPL):

    pkg> activate .
    pkg> registry update
    pkg> update
    pkg> instantiate
 
Then press `delete` to exit the package manager.

On MacOS, it is necessary to ignore package hashes for the dependence on Exodus.jl:

    ENV["JULIA_PKG_IGNORE_HASHES"] = 1

If you are getting errors regarding ssl certificates in the above setup, please try the following fix.  First, go to ~/.julia/registries and manually cllone JuliaRegistries/General.git: 

    cd ~/.julia/registries
    git clone https://github.com/JuliaRegistries/General.git
    
Then, please do

    export JULIA_SSL_CA_ROOTS_PATH=/etc/ssl/certs/ca-bundle.crt

and try the above workflow again.

To run the code, assuming that Julia is in the executable path:

    julia --project=@. /some_path/Norma.jl/src/Norma.jl input.yaml

It follows that, to run tests, assuming the Julia is in the executable path and you are in the Norma.jl/test directory:

    julia --project=@. ./runtests.jl 

To run Norma from inside a Julia session, e.g., to run the examples/ahead/overlap/cuboid/dynamic example:

    cd /some_path/Norma 
    julia
    ]
    activate .
    using Norma
    cd("examples/ahead/overlap/cuboid/dynamic")
    Norma.run("cuboid.yaml") 
    
Warning: if you make a change to Norma, you need to reload Norma module (using Norma) for those changes to get recompiled in.
