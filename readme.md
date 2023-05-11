# PSEncrypt

Exchanging documents and data _securely_ between users can be a pain.
Within an organization, it is simple enough, but with s/MIME not always an option, sharing documents via OneDrive or similar technologies often inhibited by corporate policies, things can get complicated. Fast.

This is where PSEncrypt steps in and allows for 1:1 encrypted document transfers via any medium capable of transporting files or text.

## Installation

To install the module from the PSGallery, run this line:

```powershell
Install-Module PSEncrypt -Scope CurrentUser
```

## Setting Up

To set yourself up to use PSEncrypt, both parties first need to ...

+ Create their own certificate
+ Export the contact information of their own certificate and exchange those with each other
+ Import the contact information of the other person as a contact

> Create your own certificate

```powershell
# Autodetect the name to use
New-PseCertificate

# Explicitly specify a name instead
New-PseCertificate -Name 'fred@contoso.com'
```

> Export contact information

```powershell
Export-PseCertificate -Path .\fred.contact.json
```

> Import contact information

```powershell
Import-PseContact -Path .\max.contact.json
```

## Exchanging Documents

With the previous setup done, exchanging documents securely becomes quite simple:

```powershell
# Sender
Protect-PseDocument -Path .\report.xlsx -Recipient max@fabrikam.org
```

```powershell
# Recipient
Unprotect-PseDocument -Path .\report.xlsx.json
```

> The recipient verifies the sender certificate, only accepting data signed by a registered contact.
