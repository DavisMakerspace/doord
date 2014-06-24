# doord

`doord` is a Unix domain socket server providing high-level access to the door control and monitoring hardware via GPIO.

## Cloning and pulling from the repository

This project uses a git submodule, so you can clone like this:

    git clone --recursive https://github.com/DavisMakerspace/doord.git

And update like this:

    git pull --recurse-submodules

## Configuring

In `etc`, copy the `doord.conf.example` file to `doord.conf`, and change any values that need to be changed.

## Running

Just run the `bin/doord` executable in whatever matter you see fit.

## Installing

The provided `Makefile` has an install rule that will install systemd service definitions pointing back to this directory.

## Testing

A Redis database can be used to test out the functionality without having a GPIO bus.

Just run your Redis server, and set the environment variable DOORD_FAKEGPIO before running `bin/doord`:

    DOORD_FAKEGPIO= bin/doord

To see what it would be like to have a door hooked up, you can then run `bin/door-simulator`.
