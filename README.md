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
import Pkg; Pkg.add("CSV")
import Pkg; Pkg.add("DataFrames")
import Pkg; Pkg.add("ProgressMeter")
```

You can then exit the REPL by running:

```
exit()
```

In order to test that the code is now working, run a test simulation by calling:

```
julia src/run.jl --test-run
```

# Running the Code

In order to run the code in the terminal, make sure that you are in the root of the project and run any of the following command configurations

### Test run

In order to do a test simulation that just flies with constant throttle and pitch for 40 seconds, run:

```
julia src/run.jl --test-run
```

### Running Q-Learning

To run Q-learning, enter the command below. Please see the Configuration section on additional details on how to configure your run.

```
julia src/run.jl --q-learning
```

### Deleting a run

Since I often found the need to delete runs while training and modifying the code, there is also a function to delete a run:

```
julia src/run.jl --delete-run [run_number]
```

# Configurations

Much of the code is organized to pull inputs from configuration files located in the `configs/` folder. There are three primary configurations that you may want to change:

### `simulation_config.yaml`

This configuration deals with the setup of the actual simulator, including what plane you are flying, the basic geometry of the situation, the timestep, the bounds on the actions, and the uncertainty on the observation. Some of the parameters (such as `planet`, `scene_params`, and `plane`) refer to other configuration files for improved organization.

### `model_config.yaml`

This configuration sets up the actual learning part of the code, including the discretization of the observation and action spaces, the number of training and testing iterations, and various hyperparameters used in the learning process. One note is that the discretization parameters are lists of the values at which two bins are separated. i.e. if a variable is defined by [-5, 0, 5], this means there are 4 bins: -inf to -5, -5 to 0, 0 to 5, and 5 to infinity. For the action discretization, action values are sampled at the center of their bin (with the infinities being replaced by the action bounds).

### `saving_config.yaml`

This configuration hopefully makes it easier to parameterize how different artifacts are saved throughout the training process. You can toggle all saving on and off as well as the saving of training trajectories, testing trajectories, and intermediate models as the training progresses. You can also parameterize the number of iterations you want between each of these saving actions. All files are saved into the `outputs/` folder.

# Git Stuff:

## Initial Setup:

In order to set up Github in VS code for the first time, run these two commands in the terminal:

```
git config --global user.email [your email]
git config --global user.name [your username]
```

## Feel free to text Henry if you need help!!!

## Workflow using VS Code:

#### 1. Pull:

Whenever you start coding something its a good idea to pull in the latest version by going to the "Source Control" side bar and hitting the "sync" button (or the "pull" button at the top of the graph section).

#### 2. Do your coding

#### 3. Send in your Code:

When you are done coding, go to the "source control" tab, hit the "+" button to the right of the word "Changes". Then type a message into the "Message" box and hit "Commit". Finally, hit the blue "sync" button and ideally everything should just work.

## Workflow using the terminal

The process in the terminal is effectively the same but it just uses commands instead of VS Code buttons:

#### 1. Pull:

Run this in the terminal:

```
git pull
```

#### 2. Do your coding

#### 3. Send in your code:

Run the following commands:
```
git add .
git commit -m "commit message"
git push
```

#### Some other fun commands:

If you want to figure out what is currently going on with git, you can get some info by running:

```
git status
```

# Implementation Todos:

- [x] Make Discretization configs
- [x] Make Discretized observation
- [x] Make q learning update function
- [x] Make q table tracking function
- [x] Change action handling so it just sets the throttle to the action throttle (instead of changing it)
- [x] Make csv output functions
- [ ] Reach: Make python visualization