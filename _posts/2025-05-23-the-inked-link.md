---
layout: post
title: The Inked Link
category: projects
description: Managing the challenges of a public voting website
thumbnail: /assets/img/posts/the-inked-link-thumb.png
image: /assets/img/posts/the-inked-link-thumb.png
tags: aws
---

[<b>The Inked Link</b>](https://www.theinkedlink.com/about) is a performance art project by
[Briony Godivala](https://www.instagram.com/brionygodivala/)
which features her getting a QR code tattoo and letting
the public vote where it redirects to every day.

I was given free reign on the technical challenges of this:
- How to redirect the tattoo to a chosen website
- How to setup a voting website to do this programatically

and last but not least

- How to allow convenient voting from a browser while limiting spam


## Redirection

The first point was easy. 
All one has to do is buy a domain, ensure auto-renew is on (!!)
and then link up a website or back-end server to respond to the url
on the QR tattoo.

In this case, to keep the QR as short (and therefore simple) as possible,
we decided to link it to `theinkedlink.com`.
This way once the project is over, it can host an archive of the project
or simply redirect to a personal website.

The website or backend server responding to https://theinkedlink.com
can then look up the real link the audience voted for that day
and redirect to that. 


## ...Programatically

Well we need for the public to be able to vote so ... website.

I pulled out a React project (Typescript of course)
with a Material UI theme which is the go to for not having
to muck around in CSS and getting something that looks good
out of the box.
Briony actually ended up wanting something very
early internet and minimalistic so most of the 
Material UI elements were scrapped in favour of 
default theming which was an unusual experience working
back the way to make something less styled.

The website pulls a list of the current votes from today's date
and allows the users to vote for one of the items or
submit their own link.


## Backend
I used AWS for pretty much everything in this project
from `Route 53` for domain management, `Amplify` for hosting the front end
and `API Gateway`, `Lambdas`, `DynamoDB` etc for the API's.

This was done to make the project easily scalable and proved
very useful as the website started to get good and not so good
attention.
They also have a very generous free tier which most of our
services have kept under so far, and using things like
`Lambda` allows big cost savings for smaller projects
compared to running machines 24/7.

The entry point for all requests is an 
[API Gateway REST API](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-rest-api.html)
which allows integration with downstream Lambda functions,
as well as having useful in-built features like
Rate Limiting which was turned on very quickly during the project.

The Lambdas are split by endpoint functionality
- Getting and updating votes
- Tracking user ids to ensure no spam votes
- History endpoints to aggregate votes from all previous days
- Email sending and verification

Each lambda typically has an associated database it talks to
(or several in some cases like vote validation).
I chose [DynamoDB](https://aws.amazon.com/dynamodb/)
simply because it's less hassle to work with than SQL
databases, especially when the models might evolve
throughout the development lifecycle.

The access patterns for the votes proved to be an interesting challenge.

I ended up having a single `votes` table with a date-url index for 
querying by a particular date (e.g. getting a list of today's votes)

![](/assets/img/posts/the-inked-link/date-url-index.png)
_Date_Url_Index_

as well as being able to get any item directly
by knowing the `url` and `date`.


## Limiting Spam

So far, so good, right?

As the site started to get more popular,
we gathered some attention from certain internet groups
that would put in some amount of effort in ensuring
their vote won and getting around one vote per person policies.
(if you want to see what this leads to check out the 
[voting history](https://www.theinkedlink.com/history)
in March and bring eye scrub).

The initial protections of the website were admittedly naive
as I assumed this to be a project that mostly
reaches local friends & co and assumed goodwill.
Initial implementation stored a `userId` cookie in the browser
and only allowed each browser on a device to vote
once per day. There are a million ways to get around
this but it worked for the average user who didn't
care about breaking the website.

Once we saw people starting to figure out
they can use a private tab or different browsers
to get around this, I added another layer of protection
attaching an address and User Agent of each vote.
This meant you couldn't spam by opening and closing
private tabs anymore, and total votes per ip address
could be limited to a sensible number.
Not perfect but this stops the general public
from getting easy votes in.

Then came the script kiddies.
A `User-Agent` header can be easily faked with 
a script and changing ip address is trivial
if you're using remote machines or a mobile network.
This started to become a bit of a challenge as
we didn't want to have user's signing up or
entering their details into the website.
I added a Captcha (AWS coming in handy again) which at least should
stop low level python request scripts. Still possible to automate and 
get around but browser automation is more of a pain - I was doubtful
anyone would spend that much effort just to vote for something
silly on a website. Right?

You've guessed the theme of this section already.
At this point I didn't see how we could keep the voting 
completely anonymous if people were willing to put
in the effort of automating browser actions and solving captchas
just to make their vote win.
A [proof of work](http://www.hashcash.org/) algorithm was considered which 
was an interesting way to keep things anonymous
and interaction free for the real users but given
the amount of effort already put by people to break the website
this seemed like another delay rather than a solution for good.
Phone verification seemed nice but turned out to 
be rather [expensive](https://www.twilio.com/en-us/sms/pricing/gb)
so email verification seemed to be the way forward.

The amount of effort in scripting a way to get past 
this has finally seemed to even out the playing field.
By accepting well known email providers only
we ensure the sign up process for fake addresses is lengthly and manual
as well as stopping tricks like adding `.` to email addresses
to make the same email appear as different strings.

This has been a reminder for any public facing application - 
<b>Trust but Verify</b>.


{% include post-footer.html postId="the-inked-link" %}