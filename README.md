# FuncGetRosUpdateAge
Mikrotik RouterOS script for obtaining information about the age of the last relevant update on the specified update channel.
- Supports plain text information output
- Supports detailed information output in associative array format

### Disclamer and expression of gratitude
Main source of internal functions here is https://forum.mikrotik.com/viewtopic.php?t=200103  
Main contributors to code that make this script possible are:  
@rextended, @diamuxin, @texmeshtexas and others.

# Installation
## Uploading FuncGetRosUpdateAge.rsc to Mikrotik
Use `Files -> Upload...` in winbox menu and select FuncGetRosUpdateAge.rsc to be uploaded to Mikrotik.  
Or fetch file directly from GitHub:
```
/tool fetch url="https://raw.githubusercontent.com/ahpooch/FuncGetRosUpdateAge/refs/heads/main/FuncGetRosUpdateAge.rsc" mode=https dst-path="FuncGetRosUpdateAge.rsc"
```
Use `dst-path=YOUR_PATH\FuncGetRosUpdateAge.rsc` to specify your preferred path if you like.
## Importing FuncGetRosUpdateAge
```
:import FuncGetRosUpdateAge.rsc
```
Use `YOUR_PATH\FuncGetRosUpdateAge.rsc` if you placed the script in your preferred path.  

### Importing FuncGetRosUpdateAge at startup
You could set a scheduler to import FuncGetRosUpdateAge at startup:
```
/system scheduler add name=FuncGetRosUpdateAgeImport start-time=startup interval=0 comment="FuncGetRosUpdateAge scheduled task to import itself on startup." on-event={ :import FuncGetRosUpdateAge.rsc }
```
Use `YOUR_PATH\FuncGetRosUpdateAge.rsc` if you placed the script in your preferred path.

# Usage
## Obtain information for current Ros version and channel
```shell
[admin@MikroTik] > :put [$FuncGetRosUpdateAge]
# Output: The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release.
```

## Obtain information for current Ros version on channel stable with age expressed in minutes
```shell
[admin@MikroTik] > :put [$FuncGetRosUpdateAge channel="testing" outputTimeUnits="minutes" ]
# Output: The age or latest update 7.19beta2 for Ros v7 on testing channel is 392 minutes since release.
```

## Obtain information about latest update for Ros v6 on testing channel with age expressed in seconds
```shell
[admin@MikroTik] > :put [$FuncGetRosUpdateAge version=6 channel="testing" outputTimeUnits="seconds" ]
# Output: The age of latest update 7.12.1 for Ros v6 on testing channel is 40528388 seconds since release.
```

## Obtain information about latest update in assotiative array form
```
[admin@MikroTik] > :put [$FuncGetRosUpdateAge outputFormat="keyValue"]
# Output: currentVersion=7.16.1;newerUpdateAvailable=true;pretty=The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release.;timeUnits=days;updateAge=4;updateBuild=1740386822;updateVersion=7.18
```

## Obtain information about newer update availability in a boolean form
```shell
[admin@MikroTik] > :put ([$FuncGetRosUpdateAge outputFormat="keyValue"]->"newerUpdateAvailable")
# Output: true
```

## Be aware of the special case - "long-term" channel for Ros v7:
```shell
[admin@MikroTik] > :put [$FuncGetRosUpdateAge version=7 channel="long-term" outputFormat="keyValue"]
# Output: Value "long-term" for parameter "channel" not yet supported for Ros v7.
# Output: You could check if correct build version published at https://upgrade.mikrotik.com/routeros/NEWESTa7.long-term
# Output: and if so, you should create a PR or open new issue at https://github.com/ahpooch/FuncGetRosUpdateAge
```

# Return objects structure:
## Return object for 'keyValue' outputFormat
Associative array in a following format:
```shell
{
  newerUpdateAvailable=true;
  currentVersion="7.10.1";
  updateVersion="7.12.1";
  updateBuild="1740386822";
  updateAge=5;
  timeUnits="days";
  pretty="The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release."
}
```
## Return object for 'pretty' outputFormat
A string containing information about the newest update available, compliant with the provided input parameters in a following format:
```shell
"The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release."
```