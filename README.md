# SquidGuard Adblock

A simple shell script that converts Adblock Plus lists into expressions files compatible with SquidGuard.

Many similar scripts exist, but some are quite old and use `sed` patterns that actually cause segmentation faults when SquidGuard attempts to parse them.

### Setup

First you'll need to have Squid and SquidGuard installed. This should be easily achieved through your Linux distribution's package manager.

Depending on your setup you may need to change the following variables:

```
SQUID_USER="squid"
SQUID_CONF_DIR="/etc/squid"
```

`SQUID_USER` is the user account that squid runs under. Often, this is `squid`, in other Linux distributions it could be `proxy` or something else. 

Additionally this script assumes the default config path of is `/etc/squid`. You may need to change `SQUID_CONF_DIR`.

Apart from these two variable, the script tries to detect all other config paths/files without user input or setting a value that's geared towards a specific distro, the script will output what it thinks is correct, you have the option of reviewing this before the script continues. If there are problems detecting file paths, report as an issue, describing your setup.

### Installation

You can either clone or download the master/release .zip and extract it anywhere on the machine you are going to run SquidGuard. Start by running `chmod` on the shell script.

`chmod +x get-easylist.sh`

Then just run the script with:

`./get-easylist.sh`

The lists will be automatically be downloaded and converted. The conversion will need a bit of processing power as they can be quite large.

### Adding the Adblock expression files to SquidGuard

After a successful conversion, you'll need to setup your `squidguard.conf`. You will need a new `dest` that is then attached to an `acl`

```
dest adblock {
        expressionlist adblock/easylist
        expressionlist adblock/easyprivacy
}
```

This example uses the two default lists provided, you will need to add additional references if you added more.

```
acl {
        default {
                pass !adblock all
        }
}
```

#### Replacing ads with a blank image file

You should also put in a redirect directive in your dest block, with a 1x1 transparent gif. This is for when ads that match the expression list are found and simply get replaced by this image. You can find a 1x1 blank.gif image on at the root of the repo. This needs to be hosted on a web server and referenced like so in the `dest` block:

```
redirect http://yourwebsite.com/blank.gif
```

### Comparison to Adblock Plus Browser Addon

There are advantages and disadvantages of running Adblock expression lists through Squid, I'll cover them here:

#### Advantages

* Applied at the proxy level, no need for browser addons for each client
* Ad filtering for devices that don't support browser addons but can use a user specified HTTP proxy
* Useful for devices with low RAM as the proxy will take care of all the filtering
* Being able to point mutiple clients at the proxy means you don't have to configure each client with ad blocking

#### Disadvantages

* Cannot detect JavaScript based ads
* Ad space can often be left behind, where as the browser addon generally is better at removing the entire space

### Known Issues/Roadmap

* Adding expression lists to SquidGuard is a manual process currently
* Potential issues with auto-detecting directory/config paths

I hope to make improvements to the script in the future

### Contributing

Pull Requests and feedback welcome!
