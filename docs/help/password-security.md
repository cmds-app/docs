# Password security

Every so often, someone signing in to CMDS asks a fair question:

> If the system does not know my password, how does it know when I have entered the wrong one?

It is a good question, and the answer is the reason your password stays safe even in the unlikely event that someone reaches the database. CMDS never stores your password. It cannot tell you what your password is, because it does not have it. What it keeps instead is just enough to *recognize* the right password without ever holding it.

## The short answer

When you set a password, CMDS runs it through a one-way function and stores only the result: a scrambled fingerprint that cannot be turned back into the password. When you sign in, it runs the very same function over whatever you just typed and compares the two fingerprints. If they match, the password was right. If they differ by even one character, it was wrong.

Think of it like a wax seal. A seal proves a letter came from the right signet ring without the ring ever leaving the sender's hand. The stored fingerprint proves you know your password without your password ever being stored.

## Why not just store the password?

Keeping real passwords is the thing that turns one break-in into everyone's problem. If a database held passwords and it were ever copied, every account would be open at once, and because people reuse passwords, the damage would spread to their other accounts too.

A stored fingerprint gives an attacker who copies the database nothing they can sign in with. They would have to guess passwords and fingerprint each guess one at a time, which is exactly the work CMDS makes deliberately slow.

## What actually happens

**When you set or change your password.** CMDS generates a fresh, random *salt* - a chunk of random data unique to that password - and combines it with your password through the hashing function many times over. It then stores three things together: the salt, the number of times the function was applied, and the resulting fingerprint. The password itself is not among them.

**When you sign in.** CMDS reads back your salt and iteration count, runs the password you just typed through the same function the same number of times, and compares the new fingerprint against the stored one. A match means correct; anything else means wrong.

The random salt is why two people who happen to choose the same password still end up with completely different fingerprints, and why an attacker cannot pre-compute one giant table of common passwords and match it against the whole database at once.

## How it works, in detail

For readers who want the specifics, this is the actual mechanism. The logic lives in the `PasswordHash` class in the `Shift.Common` library, and the sign-in check is in the user record (`User.cs`).

- **Algorithm.** PBKDF2 (Password-Based Key Derivation Function 2) over SHA-1, using the .NET `Rfc2898DeriveBytes` implementation.
- **Salt.** 24 random bytes, generated per password each time one is set.
- **Iterations.** The password is run through PBKDF2 1,000 times. The count is stored alongside the hash and can be raised later without invalidating existing passwords, because each stored hash carries the count it was made with. A higher count makes every guess more expensive for an attacker.
- **Output.** A 24-byte fingerprint.
- **Storage format.** The three parts are held as a single colon-separated string, `iterations:salt:hash`, with the salt and hash Base64-encoded - for example `1000:<salt>:<hash>`. It lives in the user record's `UserPasswordHash` field. The salt and the iteration count are not secret; only the password is, and it is never stored.
- **Comparison.** The stored fingerprint and the freshly computed one are compared in length-constant time, so a rejected sign-in takes the same amount of time whether the first character was wrong or the last. That keeps the timing of a rejection from leaking a hint about how close a guess was.
- **In code.** Setting a password calls `CreateHash(password)`. Checking one calls `ValidatePassword(entered, stored)`, which pulls the salt and iteration count out of the stored value, recomputes the fingerprint from the entered password, and reports whether the two match.

## What this means for you

- **We cannot look up your password.** If you forget it, support cannot read it back to you, because it was never stored. They can only reset it, which replaces the stored fingerprint with a new one.
- **A strong password still matters.** The fingerprinting protects the stored form, but a short or common password is still easy to guess. Length is the single biggest thing working in your favour.
- **Reuse is where the risk returns.** Because CMDS stores no password, a CMDS breach cannot hand yours out - but that protection ends the moment the same password is used on a site that stores it carelessly. Use a password here that you use nowhere else.
