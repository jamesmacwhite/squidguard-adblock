# SquidGuard Adblock

A simple shell script that converts Adblock Plus lists into expressions files compatible with SquidGuard.

Many similar scripts exist, but some are quite old and use `sed` patterns that actually cause segmentation faults when SquidGuard attempts to parse them.

### Setup

The script is designed to automatically detect the required aspects of your Squid and SquidGuard configuration, paths, file locations etc. When you run the script it will output what it thinks is correct, with the ability to stop the script if anything is wrong.

While I try and test this script on multiple linux distributions, there may be issues with detection in some cases. If you experience any problems, please file an issue on GitHub and I'll look into it.

### Installation

You can either clone or download the master/release .zip and extract it anywhere on the machine you are going to run SquidGuard. Start by running `chmod` on the shell script so you can execute it

```shell
chmod +x get-easylist.sh
```

Then just run the script with:

```shell
./get-easylist.sh
```

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

### Automatic updates of expressions lists via cron

The Adblock list files themselves are updated quite regularly, you can also run this script through cron, you just need to pass an additional parameter to avoid the user confirmation prompt:

```shell
./get-easylist.sh bypass_check
```

You can then schedule the job through cron, be sure to update the path of where you've actually stored the script:

```shell
0 0 * * * /path/to/get_easylist.sh bypass_check >/dev/null 2>&1
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

### Contributing

Pull Requests and feedback welcome!
