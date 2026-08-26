# Single Sign-On

Single Sign-On (SSO) is an authentication scheme that allows a user to log in with a single ID to any of several related, yet independent, software systems.

Refer to this Wikipedia article for background information about [Single Sign-On](https://en.wikipedia.org/wiki/Single_sign-on).

CMDS supports three industry-standard mechanisms for SSO:

1. Microsoft Office 365
2. Google
3. Microsoft Entra ID (formerly Azure Active Directory)
4. Security Assertion Markup Language (SAML)
5. Learning Tools Interoperability (LTI)

We do not implement or support custom SSO mechanisms due to the potential security and privacy risks associated with them.

## Learning Tools Interoperability (LTI)

Here are some additional details for using LTI for SSO with the CMDS platform.

While LTI is not primarily designed as a SSO mechanism, some of the data it passes in a launch request is about the user. LTI works on the basis of a trust relationship between systems, which is established by means of a key and a secret. This makes it much simpler than providing access to a common identity server.

In LTI, a user is authenticated by a primary system and then can be passed to another system (internal or external) by way of a signed launch message. The system that receives this message verifies its authenticity by inspecting its digital signature, and then implicitly trusting the data it carries; thereby eliminating the need to authenticate the user a second time or reconfirm the user's identity.

This approach makes LTI a low-cost option for implementing SSO between systems.

Refer to this article for details: [LTI as a SSO Mechanism](https://www.imsglobal.org/learning-tools-interoperability-sso-mechanism)

An LTI launch message submitted for SSO access to CMDS looks something like this:

![LTI launch message example](../../assets/developers/lti-launch.png)

The LTI Launch message is signed with a secure digital signature, using [HMAC-SHA1](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.hmacsha1?view=net-7.0) or [HMAC-SHA256](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.hmacsha256?view=net-7.0), with a secret key that is shared between the two systems.

When CMDS receives this message from a user's web browser, it validates the signature on the message to confirm it is a legitimate interoperability request from an authorized external system.

If the request is valid, then CMDS authenticates the learner and navigates to the requested course in the CMDS Learning Portal.
