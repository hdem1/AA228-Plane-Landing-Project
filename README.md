# AA228-Plane-Landing-Project
Final project for AA228 class at Stanford by Henry Demarest, Evan Alfandre, and Grace Hendricks.

# Installation

To get started first clone the repository. In terminal, go to where you want the repository to be stored and then run:

```
git clone https://github.com/hdem1/AA228-Plane-Landing-Project.git
```

Then open VS code and open the folder.

In order to add the relevant packages to a Julia environment, open a terminal (using the terminal tab at the top of VS Code). In the terminal run:

```
julia
```

Now you have opened the Julia REPL where you can add the necessary packages by running:

```
import Pkg; Pkg.add("YAML")
import Pkg; Pkg.add("Random")
import Pkg; Pkg.add("Distributions")
```

You can then exit the REPL by running:

```
exit()
```

In order to test that the code is now working, run a test simulation by calling:

```
julia src/run.jl --test-run
```

# Git Stuff:

In order to set up Github in VS code for the first time, run these two commands in the terminal:

```
git config --global user.email [email]
git config --global user.name [username]
```

# Running the Code

In order to run the code in the terminal, make sure that you are in the root of the project and run 

```
julia src/run.jl --test-run
```