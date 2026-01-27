# modsecurity-nginx-crs-update
A simple libmodsecurity, ModSecurity-nginx connector, and CoreRuleset updater.
Intended to run via a dpkg hook, but can be used stand-alone as well.

# Requirements

- nginx needs to be installed via apt package manager, otherwise the script needs
  to be modified to pull the nginx sources via some other means.
- libmodsecurity dependencies already need to be installed.
- Modify any hardw-coded directories or options before executing to ensure success.

The assumption of this updater is that you already have these services installed
and configured, so that the update only updates the meat and potatoes and your
configuration will still point everything to the right place.  It is not advised 
to use this script for an inital installation, though technically is will work - 
albiet with some aditional manual configuration.

# Usage
### For DPKG hook execution
```bash
sudo vim /var/lib/dpkg/info/modsecurity-nginx.triggers
```

```
interest nginx
```

```bash
sudo vim /var/lib/dpkg/info/modsecurity-nginx.postinst
```

```bash
#!/usr/bin/env bash

/usr/local/bin/update-modsecurity-nginx.sh || true
```

```bash
sudo chmod +x /var/lib/dpkg/info/modsecurity-nginx.postinst
```

### Clone the project

```bash
git clone https://github.com/RooHTaylor/modsecurity-nginx-crs-update.git
cd ./modsecurity-nginx-crs-update
sudo cp ./update-modsecurity-nginx.sh /usr/local/bin/.
```

The script will update libmodsecurity from sources, and build the modsecurity-nginx
connector module. The module is automatically moved to `/usr/lib/nginx/modules/`.

CRS rules are placed in `/etc/coreruleset/coreruleset` and plugins will be put 
in `/etc/coreruleset/plugins`.