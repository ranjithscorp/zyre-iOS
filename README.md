# zyre-compiled-libraries
Zyre - an open-source framework for proximity-based peer-to-peer applications
Source - https://github.com/zeromq/zyre

* This includes zyre library and its dependant libraries(czmq, libzmq, libsodium) compiled for iOS architectures (armv7, armv7s, arm64, i386, x86-64).
* Drag and drop the libraries in xcode project to start building zyre based iOS project.
* Libraries compiled to work on iOS 7 and above.

## zyre-scripts

This includes the scripts for building the library and its dependant libraries for iOS.

## Building on MacOS

To start with, you need at least these packages:
* Install Xcode (choose xcode version based on iOS version requirement)
* Install command-line tools for Xcode 
    Open Terminal and type

        xcode-select –install

* Install HomeBrew.
    In Terminal type

        ruby -e “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”

* Install libtool & pkg-config - (the C compiler and related tools).
    In Terminal type
        
        brew install libtool
        brew install pkg-config

* Install autoconf & automake - (the GNU autoconf makefile generators).
    In Terminal type

        brew install autoconf
        brew install automake

* Install cmake - (the CMake makefile generators (an alternative to autoconf)).
    In Terminal type

        brew install cmake

* Run the script - zyre.sh as root
    It will automatically download the zyre sourcecode and dependand library sourcecode and start building.


