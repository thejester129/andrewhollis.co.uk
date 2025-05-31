---
layout: post
title: The Inked Link
category: projects
description: A public voting website to redirect a QR tattoo on an artists body
thumbnail: /assets/img/posts/the-inked-link-thumb.png
tags: spam-detection public-voting aws
---

[<b>The Inked Link</b>](https://www.theinkedlink.com/about) is a performance art project by
[Briony Godivala](https://www.instagram.com/brionygodivala/)
which features the artist getting a QR code tattoo and letting
the public decide via voting where it links to every day.

I was in charge of the software for the project which included:
- A public voting website. This went viral several times on [Instagram](https://www.instagram.com/the.inked.link/) (500,000+ views!)
so plenty of traffic to manage
- Backend APIs to authenticate, daily refresh and store votes, including CAPTCHAs,
VPN checks and email verification
- Dynamic redirection from the tattoo to a voted link

Technologies Used:
- <b>React</b>
- <b>Route53</b>
- <b>Amplify</b>
- <b>API Gateway</b>
- <b>Lambda</b>
- <b>DynamoDB</b>
- <b>AWS WAF</b>

My dev [article](/posts/managing-public-voting) on more in-depth write-up of managing public voting.


{% include post-footer.html postId="the-inked-link" %}