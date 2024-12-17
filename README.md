# Norma

![Norma Contact Simulation 1](https://github.com/lxmota/Norma.jl/blob/main/doc/norma-contact-1.png)
![Norma Contact Simulation 2](https://github.com/lxmota/Norma.jl/blob/main/doc/norma-contact-2.png)

**Norma** is a Julia prototype for testing algorithms and ideas for coupling and multiphysics, primarily in solid mechanics and heat conduction.

---

## **Table of Contents**
1. [Features](#features)
2. [Installation](#installation)
3. [Running the Code](#running-the-code)
4. [Testing](#testing)
5. [Examples](#examples)
6. [Profiling](#profiling)
7. [Troubleshooting](#troubleshooting)

---

## **Features**
- Prototyping of coupling and multiphysics algorithms.
- Applications in solid mechanics and heat conduction.
- Designed for extensibility and experimentation.

---

## **Installation**

### Clone the Repository
```bash
cd /some_path
git clone git@github.com:lxmota/Norma.jl.git
cd Norma.jl
julia
```

### Set Up the Environment
Within the Julia package manager (enter by pressing `]` in the Julia REPL):
```julia
pkg> activate .
pkg> registry update
pkg> update
pkg> instantiate
```
Press `Backspace` or `Delete` to exit the package manager.

---

## **Running the Code**

To run the main program, assuming Julia is in your executable path:
```bash
julia --project=@. /some_path/Norma.jl/src/Norma.jl input.yaml
```

To run `Norma` interactively from a Julia session:
```bash
cd /some_path/Norma
julia
using Pkg
Pkg.activate(".")
using Norma
```
Then, navigate to your desired example folder and run the simulation. For example:
```julia
cd("examples/ahead/overlap/cuboid/dynamic")
Norma.run("cuboid.yaml")
```

**Note**: If you make changes to the `Norma` code, you need to reload the `Norma` module (`using Norma`) for those changes to take effect.

---

## **Testing**

To run the test suite using the Julia REPL, following standard Julia conventions:
```julia
using Pkg
Pkg.test()
```

Alternatively, from the command line:
```bash
julia --project=@. ./runtests.jl
```

---

## **Examples**

To run the `examples/ahead/overlap/cuboid/dynamic` example:
```bash
cd /some_path/Norma/examples/ahead/overlap/cuboid/dynamic
julia
]
activate .
using Norma
Norma.run("cuboid.yaml")
```

---

## **Profiling**

To identify performance bottlenecks in `Norma.jl`, you can use Julia's built-in `Profile` module and visualization tools. The following steps demonstrate how to profile the `Norma.run("input.yaml")` function:

### Step 1: Enable Profiling
Run the simulation with the `@profile` macro:
```julia
using Profile, Norma

cd("/some_path/Norma/examples/ahead/overlap/cuboid/dynamic")
@profile Norma.run("cuboid.yaml")
```

### Step 2: View the Profiling Results
Print a summary of the profiling data:
```julia
Profile.print()
```
This will display the most frequently hit lines of code during execution.

### Step 3: Visualize with `ProfileView`
To generate a graphical flame graph of the profiling results, install and use `ProfileView`:

```julia
using Pkg
Pkg.add("ProfileView")
using ProfileView

ProfileView.view()  # Open the visualization
```

This will display a flame graph where the horizontal axis represents function calls and their cumulative time, allowing you to pinpoint performance bottlenecks.

### Step 4: Optional: Export Results as HTML
For more interactive analysis, use `StatProfilerHTML`:

1. Install the package:
   ```julia
   Pkg.add("StatProfilerHTML")
   ```
2. Generate and open an HTML report:
   ```julia
   using StatProfilerHTML
   StatProfilerHTML.open()
   ```

### Example Command-Line Workflow
From the command line, you can combine profiling with Julia's REPL:
```bash
julia --project=@. -e 'using Profile; using Norma; cd("examples/ahead/overlap/cuboid/dynamic"); @profile Norma.run("cuboid.yaml")' -E 'using ProfileView; ProfileView.view()'
```
This will profile the code and open the flame graph for analysis.

---

## **Troubleshooting**

### SSL Certificate Issues
If you encounter SSL certificate errors during setup, follow these steps:
1. Go to `~/.julia/registries` and manually clone the Julia General Registry:
   ```bash
   cd ~/.julia/registries
   git clone https://github.com/JuliaRegistries/General.git
   ```
2. Set the SSL certificate path:
   ```bash
   export JULIA_SSL_CA_ROOTS_PATH=/etc/ssl/certs/ca-bundle.crt
   ```
3. Retry the installation workflow.
