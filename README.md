A PowerShell Profile for Developing and Managing Web Sites on [the DNN Platform](https://github.com/dnnsoftware/Dnn.Platform)
==================

This profile includes a number of modules, primarily supporting the "DNNing" module, which is used to create and restore DNN sites, as well as other maintenance tasks, like removing and upgrading the sites.

Getting Started
---------------
The following prerequisites are required in order to use this profile:
 - You must have relaxed the PowerShell execution policy
   - In an administrative powershell session, run `Set-ExecutionPolicy RemoteSigned`
 - Install the [PowerShell Community Extensions](http://pscx.codeplex.com/)
   - Run [the installer from Codeplex](http://pscx.codeplex.com/releases)
   - OR [install via Chocolatey](http://chocolatey.org/packages/pscx)
 - Install the 7-Zip command-line tool
   - [Via Chocolatey](http://chocolatey.org/packages/7zip.commandline)
 - SQL Server PowerShell Snap-in
   - Install SQL Server Management Server 2012 or later
 - (Optional) Install [ImageMagick](http://imagemagick.org/)
   - Install [from their website](http://imagemagick.org/script/binary-releases.php#windows)
   - [Via Chocolatey](http://chocolatey.org/packages/imagemagick.tool)
 - Setup a repository of DNN packages
   - Create an environment variable called `soft` pointing to the root of this "software repository"
   - Inside this folder, create a folder structure like this, `DNN\Versions\DotNetNuke 7`, which contains the DNN 7 community platform packages (install, source, upgrade, and symbols)
   - In addition, if you have Evoq packages, add them to `DNN\Versions\DotNetNuke PE` or `DNN\Versions\DotNetNuke EE` for Evoq Content or Evoq Content Enterprise, respectively.
   - (I realize that this structure doesn't work for everyone, and I'm open to pull request and suggestions to make it easier)

Once all of that is in place, you can clone this repository into the default PowerShell profile location (so you'll also need git installed).  From a PowerShell session:

    git clone https://github.com/bdukes/PowerShell-Profile.git $profile\.. --recursive
    
If you already have a PowerShell profile, you can clone this elsewhere and manually merge it into your existing profile.
