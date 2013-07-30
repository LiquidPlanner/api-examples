##These files show how to access the LiquidPlanner API from:

* C#
* C++
* Java
* Perl
* PHP
* Python
* Ruby
* VB.net

### If you don't already have a LiquidPlanner account, you can sign up at:

####  http://www.liquidplanner.com/

See the docs at:

####  http://www.liquidplanner.com/api

for more info on the API.

- - -

### C# 

If you don't have Visual Studio, you can get Visual C# Express free from Microsoft:

####  http://www.microsoft.com/visualstudio/en-us/products/2010-editions/visual-csharp-express

You'll need the JSON.net library from CodePlex:

####  http://json.codeplex.com/

Unzip the JSON.net library, open the LP project, and add a reference to the
JSON.net DLL in the unzipped files. 

- - -

### C++

The C++ example uses the following libraries 

 * Google Test
 * JsonCpp
 * Boost C++ Libraries
 * restclient-cpp

On Ubuntu, you can install them with:

    $ sudo apt-get install libgtest-dev

    # you will need to compile and install.
    # installed files can be found in /usr/src/gtest
    
    $ sudo apt-get install libjsoncpp-dev
    
    $ sudo apt-get install libboost-all-dev

    $ git submodule init
    $ cd inc/restclient-cpp
    
    # if you're on ubuntu 12.10 or later, use AutoMake.

    # Otherwise:

    $ git checkout 5a5e6b05e809a9d8aac32c937ba2e8654a1aa5a7
    $ make

- - -

### Java

The Java example uses the GSON library:

####  http://code.google.com/p/google-gson/

- - -

### Perl

The Perl example uses the following libraries from CPAN

 * REST::Client
 * IO::Uncompress::Gunzip
 * JSON
 * Term::ReadKey

- - -

### PHP

Uses libraries included with a standard PHP install.

On Ubuntu, you may need to install php5-curl

    apt-get install php5-curl

- - -

### Python

The Python example uses the requests library:

####  http://docs.python-requests.org/en/latest/user/install/#install

- - -

### Ruby

The Ruby example uses httparty:

####  https://github.com/jnunemaker/httparty/

- - -

### VB.net

As with C#, you can use VB.net Express:

####  http://www.microsoft.com/visualstudio/en-us/products/2010-editions/visual-basic-express

and you'll need the JSON.net library from CodePlex:

####  http://json.codeplex.com/
