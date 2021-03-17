# Lab 1

## SSH

Login to DETERLab as an user:

```bash
ssh la136cr@users.deterlab.net
```

The password is: `kKpM8Mki!FPkig!`

Then you can ssh to client/server instances:

```bash
ssh client.la136cr-lab1.UCLA136.isi.deterlab.net
ssh server.la136cr-lab1.UCLA136.isi.deterlab.net
```

## Part 1: POSIX File Permissions and 'sudo'

### Home Directory Security

Login as super user.

```bash
sudo su -
```

Create the `/admins` directory.

```bash
mkdir /admins
```

Create the groups `emp` and `wheel` (see man groupadd).

```bash
groupadd emp
groupadd wheel
```

Create the normal (i.e., non-admin) user accounts `larry`, `moe`, and `curly` using adduser. You may set the passwords to anything you like.

```bash
adduser larry
adduser moe
adduser curly
```

Add the non-admin accounts to the `emp` group by editing `/etc/group` or using `usermod`.

```bash
usermod -a -G emp larry
usermod -a -G emp moe
usermod -a -G emp curly
```

Create the admin user accounts `ken`, `dmr`, and `bwk` -- specifying that the home directory for each admin should be located at `/admins/username` -- where username is `ken`, `dmr` or `bwk`. In other words, admin homedirs are not in `/home`. (See man adduser for special homedirectory options.) You may set the passwords to anything you like.

```bash
adduser --home /admins/ken ken
adduser --home /admins/dmr dmr
adduser --home /admins/bwk bwk
```

Add the admin accounts to the `wheel` group by editing `/etc/group` or using `usermod`. (Ensure that admins are not part of the `emp` group.)

```bash
usermod -a -G wheel ken
usermod -a -G wheel dmr
usermod -a -G wheel bwk
```

add `larry`, `bwk`, and `dmr` to `ken`'s group.

```bash
usermod -a -G ken larry
usermod -a -G ken bwk
usermod -a -G ken dmr
```

add `moe`, `dmr`, and `ken` to `bwk`'s group.

```bash
usermod -a -G bwk moe
usermod -a -G bwk dmr
usermod -a -G bwk ken
```

add `curly`, `ken`, and `bwk` to `dmr`'s group.

```bash
usermod -a -G dmr curly
usermod -a -G dmr ken
usermod -a -G dmr bwk
```

On this system, default permissions for new home directories allow `other` users (i.e., users that are not the owner or in the specified group) to read and execute files in the directory. This is too permissive for us. Set the mode on the home directories in `/home` so that owner can read, write, and execute, group can read and execute and other has no permissions. (Set the mode on the homedir only -- do not set it recursively.)

```bash
chmod o-rx /home/*
```

Individual home directories should now be inaccessible to `other` users. Now, set the permission mode on `/home` itself so that normal users can't list the contents of `/home` but can still access their home directories and so that members of the `wheel` group have full access to the directory (without using `sudo`).

> read(r): Having read permission on a file grants the right to read the contents of the file. Read permission on a directory implies the ability to list all the files in the directory.
>
> write(w): Write permission implies the ability to change the contents of the file (for a file) or create new files in the directory (for a directory).
>
> execute(x): Execute permission on files means the right to execute them, if they are programs. (Files that are not programs should not be given the execute permission.) For directories, execute permission allows you to enter the directory (i.e., cd into it), and to access any of its files.

```bash
chmod o-r /home
chgrp wheel /home
chmod g+w /home
```

By default, each homedir is owned by its user, and the homedir's group is set to the group named after the user. (For example, `ken`'s homedir is set to `ken`:`ken` -- i.e., `ken` is the owner and the group is set to `ken`'s group.) Set the permission modes recursively on the individual homedirectories in `/admins` (see `man chmod`) so that:

- owners have full access
- `group` users (users who are in the group associated with a user's home directory) can read and create files in that homedir
- `other` users can read and execute any files (unlike the home directories in /home)
- files created by a group member in that homedir should be set to the homedir owner's group. (Hint: Look up what the SUID and SGID bits do on directories.)
- Example: `larry` is in `ken`'s group. `larry` can create files in `ken`'s homedir, and those files are owned by `larry`, but are assigned to `ken`'s group rather than `larry`'s group. `moe`, not in `ken`'s group, can only read and execute files. (Note that permissions for normal emp user homedirs are not changed.)

```bash
chmod 2775 /admins/*
```

### The Ballot Box

Create the `/ballots` directory.

```bash
mkdir /ballots
```

Set the permissions on `/ballots` so that it is owned by root and users can write files into the directory but cannot list the contents of the directory. Furthermore, set it so that members of the wheel group have no access (not including sudo).

```bash
chmod o-rx /ballots
chgrp emp /ballots
chmod 730 /ballots
```

**Short Answer 1**: Is there any way that employees can read the ballots of other users? If so, what could be done to stop this? If not, what prevents them from reading them?

```
Yes, if larry creates a file in ballots directory, and moe knows the name of the file, then moe can read the content of the file because the default file mode is 0664, which allows `other` to read.

To prevent this, we need to execute `chmod o-r` on every files in ballots directory.
```

**Short Answer 2**: What does the 'x' bit mean when applied to directories?

```
It means you can cd into the directory.
```

### The TPS Reports Directory

Create the `/tpsreports` directory.

```bash
mkdir /tpsreports
```

Create the `tps` user.

```bash
adduser tps
```

Set the permissions on `/tpsreports` so that it is owned by `tps` and that `tps` and members of the `wheel` group have full access to the directory, but so that no one else has access to the directory.

```bash
chown tps:wheel /tpsreports
chmod 770 /tpsreports
```

**Short Answer 3**: Which users on the system can delete arbitrary files in the /tpsreports directory?

```
root
tps
ken
dmr
bwk
```

**Short Answer 4**: Is there any way that non-wheel employees can read files in the /tpsreports directory?

```
No because `other` has no access at all.
```

**Short Answer 5**: What do '0' permissions mean for the owner of a directory? What privileges do they have over files in that directory?

```
It means the owner cannot list files in the directory, nor create a file in the directory, nor cd into the directory.
```

**Short Answer 6:** Is this safe? Why or why not? If it is not safe, is there a better way to give larry this access? If it is safe, how do you know it is safe? (Hint: search online for common sudo issues.)

Reference: https://unix.stackexchange.com/questions/181492/why-is-it-risky-to-give-sudo-vim-access-to-ordinary-users/181494

```
Granting sudo access to vim is dangerous because the user can then, for example, open /etc/sudoers inside the editor and grant full sudo access to themselves.

Instead, we can grant sudo access only for editing certain files using sudoedit:

larry ALL=(ALL) sudoedit /etc/httpd/conf/httpd.conf
```

**Short Answer 7**: Assuming the init script /etc/init.d/httpd has no unknown vulnerabilities, is it safe to grant larry sudo access to the command /etc/init.d/httpd restart? If this is not secure, explain why.

```
Yes.
```

**Short Answer 8**: Is there some way that moe or curly could subvert this system to gain root privileges? If not, how do you know this is true?

Hint: Consider what happens during the UNIX login process -- the time between when the user enters the correct password and when they can interact with their shell.

```
No because they don't have permissions to modify /etc/sudoers.
```

## Part 2: Firewall Configuration

See `firewall.sh`.
