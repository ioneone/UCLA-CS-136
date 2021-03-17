# Lab 0

## SSH

To SSH into DETERLab as an user, run:

```bash
ssh la136cr@users.deterlab.net
```

The password is: `kKpM8Mki!FPkig!`

Then you can SSH into your experiment by running:

```bash
ssh intro.Intro.UCLA136.isi.deterlab.net
```

A node's home directory is shared with the home directory of your deterlab. You can copy any file into your local machine with `scp`. In your local machine, run:

```bash
scp la136cr@users.deterlab.net:/path/to/file ./
```

Use `-r` option to transfer a folder.

## Treasure Hunt

Find all five files whose names contain the word "intro" in some form.

```bash
find / -iname "*intro*.jpeg" -o -iname "*intro*.jpg" 2>/dev/null
```

Make a directory in your home directory called top_secret.

```bash
mkdir top_secret
```

Move the 5 files into top_secret

```bash
find / -iname "*intro*.jpeg" -o -iname "*intro*.jpg" 2>/dev/null | xargs cp --target-directory=top_secret
```

## Information Hunt

1 sentence: What goes in the /var directory on a UNIX computer?

```
Data that is changed when the system is running normally such as logging and temporary files.
```

1 sentence: What is the /dev directory for on a UNIX computer?

```
It stores device files, with which you can access a piece of hardware such as hard drives.
```

On your experimental node, find out how large the disks are and how much space is free. Put this information in a separate file called top_secret/diskfree.txt. (See the infobox on command redirection for an easy way to do this.)

```bash
df -h > top_secret/diskfree.txt
```

The disk has `15GB` and `12GB` is free.

On your experimental node, find out the "vendor id" of the experimental node's CPU model. Hint: there is a dynamic file on the system that includes this information.

```bash
cat /proc/cpuinfo
```

The vendor id is `GenuineIntel`.

## Wrap it up!

```bash
tar cvzf la136cr-intro.tar.gz top_secret/
```
