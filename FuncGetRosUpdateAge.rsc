#-----------------------------------------------------------------------------------------------------#
#      Function for obtaining information about the age of the last relevant update                   #
#      on the specified update channel.                                                               #
#                                                                                                     #
#      Disclamer and expression of gratitude                                                          #
#      Main source of internal functions here is https://forum.mikrotik.com/viewtopic.php?t=200103    #
#      Main contributors to code that make this script possible are:                                  #
#      @rextended, @diamuxin, @texmeshtexas and others.                                               #
#                                                                                                     #
#      Created by: @ahpooch                                                                           #
#      GitHub source: https://github.com/ahpooch/FuncGetRosUpdateAge                                  #
#      Updated: 01.03.2024                                                                            #
#      Version: 1.0.0                                                                                 #
#-----------------------------------------------------------------------------------------------------#

### Syntax

# :put [$FuncGetRosUpdateAge version=[6 | 7] \
# channel="[long-term | stable | testing | development]" \
# source="[changelog | release]" \
# outputTimeUnits="[seconds | minutes | hours | days]" \
# outputFormat="[keyValue | pretty]" \
# ]

### Usage

# - Obtain information for current Ros version and channel
# [admin@MikroTik] > :put [$FuncGetRosUpdateAge]
# Output: The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release.

# - Obtain information for current Ros version on channel stable with age expressed in minutes
# [admin@MikroTik] > :put [$FuncGetRosUpdateAge channel="testing" outputTimeUnits="minutes" ]
# Output: The age or latest update 7.19beta2 for Ros v7 on testing channel is 392 minutes since release.

# - Obtain information about latest update for Ros v6 on testing channel with age expressed in seconds
# [admin@MikroTik] > :put [$FuncGetRosUpdateAge version=6 channel="testing" outputTimeUnits="seconds" ]
# Output: The age of latest update 7.12.1 for Ros v6 on testing channel is 40528388 seconds since release.

# - Obtain information about latest update in assotiative array form
# [admin@MikroTik] > :put [$FuncGetRosUpdateAge outputFormat="keyValue"]
# Output: currentVersion=7.16.1;newerUpdateAvailable=true;pretty=The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release.;timeUnits=days;updateAge=4;updateBuild=1740386822;updateVersion=7.18

# - Obtain information about newer update availability in a boolean form
# [admin@MikroTik] > :put ([$FuncGetRosUpdateAge outputFormat="keyValue"]->"newerUpdateAvailable")
# Output: true

# - Be aware of the special case - "long-term" channel for Ros v7:
# [admin@MikroTik] > :put [$FuncGetRosUpdateAge version=7 channel="long-term" outputFormat="keyValue"]
# Output: Value "long-term" for parameter "channel" not yet supported for Ros v7.
# Output: You could check if correct build version published at https://upgrade.mikrotik.com/routeros/NEWESTa7.long-term
# Output: and if so, you should create a PR or open new issue at https://github.com/ahpooch/FuncGetRosUpdateAge


### Return objects structure:

# - Return object for 'keyValue' outputFormat
# Associative array in a following format:
# {
#   newerUpdateAvailable=true;
#   currentVersion="7.10.1";
#   updateVersion="7.12.1";
#   updateBuild="1740386822";
#   updateAge=5;
#   timeUnits="days";
#   pretty="The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release."
# }

# Return object for 'pretty' outputFormat
# A string containing information about the newest update available, compliant with the provided input parameters in a following format:
# "The age or latest update 7.18 for Ros v7 on stable channel is 4 days since release."

:global FuncGetRosUpdateAge do={
    # named parameters that can be passed to function on call :
    # version : [ "6" | "7" ]
    # channel : [long-term | stable | testing | development]
    # source  : [release | changelog]
    # outputTimeUnits  : [seconds | minutes | hours | days]
    # outputFormat : [keyValue | pretty]
    #

    :local chosenVersion
    :if ([:len $version] > 0) do={
        :if ($version = "6" or $version = "7") do={
            :set $chosenVersion $version
        } else={
            :local returnMessage "Only \"6\" and \"7\" versions are supported."
            :log error $returnMessage
            :return $returnMessage
        }
    } else={
        :if ([/system resource get version] ~ "^6") do={:set $chosenVersion "6"}
        :if ([/system resource get version] ~ "^7") do={:set $chosenVersion "7"}
        :if ([:len $chosenVersion] = 0) do={
            :local returnMessage "Your Ros version is unsupported by this script."
            :set $returnMessage ($returnMessage . "\r\nDetected version is: " . [/system resource get version])
            :set $returnMessage ($returnMessage . "\r\nYou could create a PR or open new issue at https://github.com/ahpooch/FuncGetRosUpdateAge")
            :log error $returnMessage
            :return $returnMessage
        }
    }

    :local chosenChannel
    :if ([:len $channel] > 0) do={
        :if ($channel = "long-term" or $channel = "stable" or $channel = "testing" or $channel = "development") do={
            :if ($channel = "long-term" and $chosenVersion = "7") do={
                :local returnMessage "Value \"long-term\" for parameter \"channel\" not yet supported for Ros v7."
                :set $returnMessage ($returnMessage . "\r\nYou could check if correct build version published at https://upgrade.mikrotik.com/routeros/NEWESTa7.long-term")
                :set $returnMessage ($returnMessage . "\r\nand if so, you should create a PR or open new issue at https://github.com/ahpooch/FuncGetRosUpdateAge")
                :log error $returnMessage
                :return $returnMessage
            } else={
                :set $chosenChannel $channel
            }
        } else={
            :local returnMessage "Parameter \"channel\" should only be set to one of the following values: [long-term | stable | testing | development]."
            :log error $returnMessage
            :return $returnMessage
        }
    } else={
        :set $chosenChannel [/system package update get channel]
    }

    :local chosenSource "release"
    :if ([:len $source] > 0) do={
        :if ($source = "changelog" or $source = "release") do={
            :set $chosenSource $source
        } else={
            :local returnMessage "Parameter \"source\" should only be set to one of the following values: [release | changelog]."
            :log error $returnMessage
            :return $returnMessage
        }
    }

    :local chosenOutputTimeUnits "days"
    :if ([:len $outputTimeUnits] > 0) do={
        :if ($outputTimeUnits = "days" or $outputTimeUnits = "hours" or $outputTimeUnits = "minutes" or $outputTimeUnits = "seconds") do={
            :set $chosenOutputTimeUnits $outputTimeUnits
        } else={
            :local returnMessage "Parameter \"source\" should only be set to one of the following values: [days | hours | minutes | seconds]."
            :log error $returnMessage
            :return $returnMessage
        }
    }

    :local chosenOutputFormat "pretty"
    :if ([:len $outputFormat] > 0) do={
        :if ($outputFormat = "pretty" or $outputFormat = "keyValue") do={
            :set $chosenOutputFormat $outputFormat
        } else={
            :local returnMessage "Parameter \"outputFormat\" should only be set to one of the following values: [pretty | keyValue]."
            :log error $returnMessage
            :return $returnMessage
        }
    }

    :local timetoseconds do={
        # Function timetoseconds converts [:timestamp] from format "2877w6d13:23:56.508745456"
        # to unix Epoch timestamp in seconds.
        # Created by @rextended and published at https://forum.mikrotik.com/viewtopic.php?t=200103
        :local inTime $1
        :local wPos   [:find $inTime "w" -1]
        :local dPos   [:find $inTime "d" -1]
        :local itLen  [:find $inTime "." -1] ; :if ([:typeof $itLen] = "nil") do={:set $itLen [:len $inTime]}
        :local itSec  [:pick $inTime ($itLen - 2) $itLen]
        :local itMin  [:pick $inTime ($itLen - 5) ($itLen - 3)]
        :local itHou  [:pick $inTime ($itLen - 8) ($itLen - 6)]
        :local itDay  0
        :local itWee  0
        :if (([:typeof $wPos] = "nil") and ([:typeof $dPos] = "num")) do={:set $itDay [:pick $inTime 0 $dPos]}
        :if (([:typeof $wPos] = "num") and ([:typeof $dPos] = "num")) do={:set $itDay [:pick $inTime ($wPos + 1) $dPos]}
        :if  ([:typeof $wPos] = "num")                                do={:set $itWee [:pick $inTime 0 $wPos]}
        :local totalSec ($itSec + (60 * $itMin) + (3600 * $itHou) + (86400 * $itDay) + (604800 * $itWee))
        :return $totalSec
    }

    :if ($chosenSource = "release") do={
        :local RosVersionTag
        :if ($chosenVersion = "6") do={
            :set $RosVersionTag "NEWEST6"
        }
        :if ($chosenVersion = "7") do={
            :set $RosVersionTag "NEWESTa7"
        }
        
        :local newestRelease ("$([/tool fetch url="https://upgrade.mikrotik.com/routeros/$RosVersionTag.$chosenChannel" as-value output=user]->"data")\n")
        :local newestVersion [:pick $newestRelease 0 [:find $newestRelease "\_" -1]]
        :local newestBuild [:pick $newestRelease ([:find $newestRelease "\_" -1] + 1) [:find $newestRelease "\n" -1]]
        :local currentVersion [/system/package get [find where name="routeros"] version]

        :local currentTime [$timetoseconds [:timestamp]]

        :local calculatedAge
        
        :if ($chosenOutputTimeUnits = "seconds") do={
            :set $calculatedAge ($currentTime - $newestBuild)
        }
        :if ($chosenOutputTimeUnits = "minutes") do={
            :set $calculatedAge (($currentTime - $newestBuild) / 60)
        }
        :if ($chosenOutputTimeUnits = "hours") do={
            :set $calculatedAge (($currentTime - $newestBuild) / 3600)
        }
        :if ($chosenOutputTimeUnits = "days") do={
            :set $calculatedAge (($currentTime - $newestBuild) / 86400)
        }

        :local isNewerUpdateAvailable false
        :local prettyString
        # If chosenVersion is our current Mikrotik version then we can define newerUpdateAvailable.
        # If not then newerUpdateAvailable will always be false. But the updateAge will be present.
        :if (([/system resource get version] ~ "^$chosenVersion")) do={
            :if ($newestVersion != $currentVersion) do={
                :set $isNewerUpdateAvailable true
                :set $prettyString "The age or latest update $newestVersion for Ros v$chosenVersion on $chosenChannel channel \
                is $calculatedAge $chosenOutputTimeUnits since release."

            } else={
                :set $prettyString "You are on a latest update $newestVersion for Ros v$chosenVersion on $chosenChannel channel."
            }
        } else={
            :set $prettyString "The age of latest update $newestVersion for Ros v$chosenVersion on $chosenChannel channel \
            is $calculatedAge $chosenOutputTimeUnits since release."
        }

        :if ($chosenOutputFormat = "pretty") do={
            :return $prettyString
        } else={
            :local returnObject {
                                    "newerUpdateAvailable"=$isNewerUpdateAvailable;
                                    "currentVersion"=$currentVersion;
                                    "updateVersion"=$newestVersion;
                                    "updateBuild"=$newestBuild;
                                    "updateAge"=$calculatedAge;
                                    "timeUnits"=$chosenOutputTimeUnits;
                                    "pretty"=$prettyString
                                }
            :return $returnObject
        }
    }
} 