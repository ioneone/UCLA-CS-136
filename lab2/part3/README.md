# Lab 2

## SSH

Login to DETERLab as an user:

```bash
ssh -L 8118:pc091:80 la136cr@users.deterlab.net
```

The password is: `kKpM8Mki!FPkig!`

Then you can ssh to experiment instance:

```bash
ssh server.la136cr-lab2.UCLA136.isi.deterlab.net
```

## Part 3: SQL Injection -- FrobozzCo Credit Union

Exercise a remote SQL-Injection vulnerability to perform these unauthorized tasks on the SQL server

Show how you can log into a single account without knowing any id numbers ahead of time.

- Account ID Number: `1 OR 1 = 1`
- Password (alphanumeric only): `' OR '' = '`

Show how you can log into any account you like (without knowing any id numbers ahead of time).

- Account ID Number: `1 OR 1 = 1`
- Password (alphanumeric only): `' OR 1 = 1 LIMIT n, 1 #`

where n = 0, 1, 2, 3, 4, 5, 6, ...

Make some account (your choice) wire its total balance to the bank with routing number: 314159265 and account number: 271828182845

Just follow the UI in `Wire Funds` section and click `Wire Money` button.

Explain why you can't create a new account or arbitrarily update account balances (or show that you can).

No because `mysqli_query()` does not allow executing multiple queries, so we cannot inject a second query with `INSERT INTO` or `UPDATE` statement. There _are_ some `UPDATE` statements in `FCCU.php` source code, so we can potentially make a target account have the same balance as a source account, but we still can't _arbitrarily_ set a balance we want.
