# squidGuard/ufdbGuard Adblock expression lists

A shell script that converts Adblock Plus lists into expressions files compatible with squidGuard and ufdbGuard

Many similar scripts exist to convert such lists, but some are quite old and use `sed` patterns that actually cause problems.

### Setup

The script is designed to automatically detect the required aspects of your Squid, squidGuard or ufdbGuard configuration, paths, file locations etc. When you run the script it will output what it thinks is correct, with the ability to stop the script if anything is wrong.

While I try and test this script on multiple Linux distributions, there may be issues with detection in some cases. If you experience any problems, please file an issue on GitHub and I'll look into it.

### Installation

No formal installation is required, other than to get the source and place it on the machine you are running Squid on.

#### Git

```
git clone https://github.com/jamesmacwhite/squidguard-adblock
cd squidguard-adblock
```

#### Extract from zip

```
wget -qO- -O squidguard-adblock-master.zip https://github.com/jamesmacwhite/squidguard-adblock/archive/master.zip && \ 
unzip squidguard-adblock-master.zip && \ 
rm squidguard-adblock-master.zip
cd squidguard-adblock-master
```

Once extracted grant executable permission on the shell script:

```shell
chmod +x get-easylist.sh
```

See usage section for instructions on how to use the script

### Usage

The script requires a couple of user parameters based on what setup you are running

##### squidGuard

`./get-easylist.sh squidGuard`

##### ufdbGuard

`/get-easylist.sh ufdbGuard`

The lists will be automatically be downloaded, converted and written to the database folder of the respective URL filter. The conversion will need a bit of processing power as they can be quite large.

### Adding the Adblock expression files to squidGuard

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

### Adding the Adblock expression files to ufdbGuard

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

#### Replacing advertisements with a blank image file

You should also put in a redirect directive in your dest/category block, with a 1x1 transparent gif. This is for when adverts that match any rule in the expression list are found and simply get replaced by this image. You can find a 1x1 blank.gif image within the source. This needs to be hosted on a web server and referenced like so in the `dest` or `category` block:

```
redirect http://yourwebsite.com/blank.gif
```

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

* Applied at the proxy level, no need for browser addons for each client
* Ad filtering for devices that don't support browser addons but can use a user specified HTTP proxy
* Useful for devices with low RAM as the proxy will take care of all the filtering
* Being able to point mutiple clients at the proxy means you don't have to configure each client with ad blocking

#### Disadvantages

* Cannot detect JavaScript based ads
* Ad space can often be left behind, where as the browser addon generally is better at removing the entire space

### Contributing

Pull Requests and feedback welcome!
