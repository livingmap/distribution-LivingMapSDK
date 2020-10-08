LivingMapSDK Distribution
----

This repository contains compiled binary distributable versions of the Living Map Indoor
Positioning System.  

It supports Cocoapods, Carthage and manual distribution.

Structure:

LivingMapSDK.framework/ - The uncompressed framework used by Cocoapods.  Specific versions are tagged in Git.  
LivingMapSDK.json       - the indirection pointer file required by Carthage's "binary" option.
release                 - contains subdirectories numbered for each release.
release/X.Y.Z           - contains a LivingMapSDK.framework.zip file for Carthage.  Download and use this for manual installs.
