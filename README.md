# squidGuard/ufdbGuard Adblock Plus Expression Lists Converter

A shell script that converts Adblock Plus lists into expressions files compatible with squidGuard and ufdbGuard

Many similar scripts exist to convert such lists, but some are quite old and use `sed` patterns that actually cause problems.

### Dependencies

* bash
* wget
* squid
* squidGuard or ufdbGuard

### Setup

The script is designed to automatically detect the required aspects of your Squid and squidGuard/ufdbGuard configuration, paths, file locations etc. When you run the script it will output what it thinks is correct, with the ability to stop the script if anything is wrong.

While I try and test this script on multiple Linux distributions, there may be issues with detection in some cases. If you experience any problems, please file an issue on GitHub and I'll look into it.

### Installation

No formal installation is required, other than to get the source and to extract it to any directory on the machine you are running Squid on.

You will need to grant executable permission to the shell script before running it:

```
chmod +x get-easylist.sh
```

See usage section for instructions on how to use the script

### Usage

The script requires a couple of user parameters based on what setup you are running:

```
./get-easylist.sh [squidGuard/ufdbGuard] [autoconfirm]
```

For additional guidance, you can run the script without any parameters which will show the help message

#### Examples:

##### squidGuard

```
./get-easylist.sh squidGuard
```

##### ufdbGuard

```
./get-easylist.sh ufdbGuard
```

The lists will be automatically be downloaded, converted and written to the database folder of the respective URL filter. The conversion will need a bit of processing power as they can be quite large.

### Adding the converted Adblock expression files to your URL filter

##### squidGuard

```
dest adblock {
	expressionlist adblock/easylist
	expressionlist adblock/easyprivacy
}
```

```
acl {
	default {
		pass !adblock all
	}
}
```

##### ufdbGuard

```
category adblock {
	expressionlist  adblock/easylist
	expressionlist  adblock/easyprivacy
}
```

```
acl {
	default {
		pass !adblock any
	}
}
```

#### Replacing advertisements with a transparent image

You should also consider putting in a redirect directive in your dest/category adblock config, to serve a transparent image that will replace the original advert space/content when a expression rule matches. You can find a 1x1 blank.gif image within the source. This needs to be hosted on a web server and referenced like so in a `dest` or `category` block:

##### squidGuard

```
redirect http://yourwebsite.com/blank.gif
```

The image file could also be hosted on an internal server, as long as the server is accessible when using the proxy.

##### ufdbGuard

With ufdbGuard you have the option to run a local Apache HTTPD instance which will serve the transparent image for you as it already includes one, the settings for Apache are present in the `ufdbGuard.conf`. An example redirect in ufdbGuard that is generally non-intrusive is below:

```
redirect http://your-proxy-server.com:8080/cgi-bin/URLblocked.cgi?admin=%A&mode=default&color=red&size=normal&clientaddr=%a&clientname=%n&clientuser=%i&clientgroup=%s&targetgroup=%t&url=%u
```

Make sure you change the proxy address and port number to match your setup. It doesn't necessarily have to be a registered DNS name, an IP address will also be sufficient.

### Automatic updates of expressions lists via cron

The Adblock list files themselves are updated quite regularly, you can also run this script through cron, you just need to pass an additional parameter to avoid the user confirmation prompt:

```
./get-easylist.sh [squidGuard/ufdbGuard] autoconfirm
```

You can then schedule the job through cron, be sure to update the path of where you've actually stored the script, an example cron could be:

```
0 0 * * * /path/to/get_easylist.sh squidGuard autoconfirm >/dev/null 2>&1
```

This would run the script everyday at midnight 12 AM (00:00 AM) for squidGuard

### Comparison to Adblock Plus Browser Addon

There are advantages and disadvantages of running Adblock expression lists through Squid, I'll cover them here:

#### Advantages

* Filtering is applied at the proxy level, no need for browser addons for each client
* Enables ad filtering for devices that don't support browser addons but can use a user-defined HTTP proxy
* Useful for devices with low RAM as the proxy will take care of all the filtering
* Being able to point mutiple clients at the proxy means you don't have to configure each client with ad blocking
* Works with Squid as a transparent proxy

#### Disadvantages

* Cannot detect JavaScript based ads
* Some ad space can sometimes be left behind

### Contributing

Pull Requests and feedback welcome!