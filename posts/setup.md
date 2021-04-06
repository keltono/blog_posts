% self-host your own file sharing website
% Kelton O'Brien
If you talk to me for long enough over text, you will probably end up getting a link that looks like this:

[https://keltono.net/.share/.HyiB0R6+AcvZqFkOgpej-ascii_cats.htm](https://keltono.net/.share/.HyiB0R6+AcvZqFkOgpej-ascii_cats.htm)

or maybe one that looks like this:

[https://keltono.net/.share/screenshots/.Lq7%2bL52y6AZwg3pYdJ.png](https://keltono.net/.share/screenshots/.Lq7%2bL52y6AZwg3pYdJ.png)

I don't think I've explained my setup for sharing files and screenshots in detail yet. 
I've found it really useful, especially for files that are too large to be embedded in certain chat applications, 
or situations where embedding is not an option (IRC, this blog, my résumé, etc.). 

## Technical details
There are a few distinct parts to this.

### The server
This is probably the simplest part. Simply run an [nginx](https://nginx.org/en/) server on an internet-exposed machine, and turn on autoindexing for the folder you want. (e.g /.share).
The relevant part of my nginx.conf looks like this:
```nginx
#main
server {
    listen  443 ssl;
    root /mnt/website;
    server_name keltono.net  www.keltono.net;
    
    ssl_certificate /etc/letsencrypt/live/keltono.net/fullchain.pem;
    # ... more ssl stuff ...

    location /.share {
        root /mnt;
        autoindex on;
    }
}

```

now, when i make a file `/mnt/.share/filename` on the server, it will show up as `https://keltono.net/.share/filename` on the website. 
The one thing to note about this approach is that if you go to just `https://keltono.net/.share` you will be able to see (and click on) all of the files that are not hidden (don't start with a `'.'`).
This is not an issue if you simply make all of the files in the given directory start with a period. 
If you simply move a file to this folder without changing the name, it might be easy to guess. 
This is probably fine for some, but for the sake of privacy, adding some entropy to the file names is a good idea. 

### Filename generation
the randomness is done by just grabbing 20 characters from [/dev/urandom](https://en.wikipedia.org/wiki//dev/random) and then converting that to base 64.
this is just a one line function.
```bash
randomPath() {
  echo .$(head /dev/urandom -c 20 | base64 | head - -c 20 | tr -d /)
}
```
for functions that take in a specific file, (i.e, the file sharing command, but not the screenshot command), this is combined with the given file to get the desired result -- something like `PATHNAME=$(randomPath)-$(basename "$1")`.

After this, the new filenames may not be valid urls, such as if spaces are in the filename. For this, the `rawurlencode` function is used. 
``` bash
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}" 
}
```
This and the `randomPath` function are both helper functions for the functions that do all of the interesting things.

### File upload
now that most of the bookkeeping is done, these functions are relatively simple. Now we just rsync the file up to the server.

```bash
share() {
  PATHNAME=$(randomPath)-$(basename "$1")
  rsync -avzz $1 servername:/path/to/.share/"$PATHNAME"
  echo https://your.website/.share/$(rawurlencode "$PATHNAME")
}
```
There you go! Click or copy that link and you should have a link to the file you wanted to share.
If you're feeling extra lazy, you can also have it copy the link into your clipboard automatically by changing the last line to
`echo https://your.website/.share/$(rawurlencode "$PATHNAME") | tee /dev/tty | xclip -sel clip`
(if you use X11. I'm sure there's an xclip equivalent for wayland).

the command for taking a screenshot is almost identical, just with a couple extra lines for actually taking the screenshot.

```bash
sc() {
    maim -s /tmp/temp_screen_cap.png
    PATHNAME=$(randomPath)
    rsync -avzz /tmp/temp_screen_cap.png cattown:/mnt/.share/screenshots/"$PATHNAME".png
    u="https://keltono.net/.share/screenshots/$(rawurlencode "$PATHNAME").png"
    echo $u
    echo $u | xclip -sel clip
    rm -f /tmp/temp_screen_cap.png
}
```
You will need to have [maim](https://github.com/naelstrof/maim) installed for this to work. Scrot also works fine.

You can can put these in your your `~/.bashrc`, `~/.bash_aliases`, or in a separate shell script that you can bind to a hotkey (such as printscreen).
If you have a device with reasonable uptime and download/upload speeds, you already have a much nicer alternative to imgur or dropbox or what else have you that you can use easily in the command line.


Although It would not be super difficult to wrap this up into a neat package, the product is sufficiently simple where I think it being a set of bash scripts invoking rsync is fine.


Being self-hosted, there are several advantages over commercial image/file hosting websites.
Firstly, you can link directly to the file you want -- no mandatory javascript, ads, or bloat.
Secondly, you don't have to depend on some other website. 
If you use a non-self-hosted solution, it might disappear one day (RIP firefox send) or become terrible (RIP imgur). 
In my view, trying to send someone a large file is an unsolved problem unless you have a set up like this. 

## Future plans

You may notice that this doesn't really work well for systems you don't have terminal acess to. 
Or non-unix machines. Or phones. The future work involves writing a quick website in [flask](https://flask.palletsprojects.com/en/1.1.x/) or [rocket](https://rocket.rs/) that has the same function with a basic interface.
I will update this post with an addendum if/when that happens.
