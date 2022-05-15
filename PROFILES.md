# Archive profiles
This are the files that specify what files will be backed up

## How to create one
First of all you should know where this file is going to run and what tools you got
to work with and what you have to implement, this file is sourced inside the library of the script.

### What you can work with

**'SCRIPT_DIR' variable**

the directory of the project (can be used to source other profiles or functions if you need to)
look on [this](./profiles/default-kde) profile to see a good use for it.

**'add_entries_to_archive' function**

This [function](https://github.com/nonoMain/keeper/blob/master/keeper.sh#L34-L48) will be used to add the lists of files you want to add to the archive at the given path from the given path
look on [this](./profiles/default) profile to see how it is used.

### What you need to implement

#### use_profile_backup function

This function will be called right after sourcing the profile and is the 'main' function
of the archive profile.

It should call all the functions that list your target files
look on the [function](https://github.com/nonoMain/keeper/blob/master/profiles/default#L72-L77) in the default profile for an example on how to use it
if you want to merge multiple profiles then look [here](./profiles/default-kde) to see how I did it.
