---
layout: post
title: NAS Sync Android
category: projects
description: Google Photo Cloud at home on a Raspberry PI
thumbnail: /assets/img/posts/nas/thumb.jpeg
image: /assets/img/posts/nas/thumb.jpeg
carousels:
  - images: 
    - image: /assets/img/posts/nas/nas1.png
    - image: /assets/img/posts/nas/nas2.png
    - image: /assets/img/posts/nas/nas3.png
---

Have a <b>Raspberry Pi</b> lying at home gathering dust?
Buy a cheap SSD and turn it into a home google cloud!

[Open Media Vault](https://www.openmediavault.org/)
turns your Rasperry PI (or any Debian Linux device, so old laptops
can also be used here) into a fully functioning 
Network Attached Storage device.
This means you can store and access files from any device
on your home network.

I initially wanted to try this for work purposes - 
I switch between Windows and Mac for mobile development
and after watching too much 
[Wolfgang](https://www.youtube.com/@WolfgangsChannel)
thought it would be great if I didn't have to clone
every repo twice on each computer and be able to pick up
local git branches no matter where I started the work.
However I found that using a network drive with git and editors
is quite slow and problematic so this efficiency dream
has been put to bed for now.

Then the 
[QNAP Ransomware Attack](https://www.reddit.com/r/lexfridman/comments/sdtsjn/lex_fridman_on_instagram_i_just_got_hacked/)
happened.
I thought - why should I backup all my personal photos in some remote server
with limited storage and pay for this service when there's a perfectly good
500gb drive sitting 2 meters away from me?
The main limitation is I could only sync my phone when at home
(obviously not wanting to expose the NAS to the internet)
but that seemed perfect for my use case.
OMV even supports reduntant backup drives if I wanted an
even more robust solution in the future.
I got to work.

I decided on a simple interface that fit my needs
- A way to create a mapping between a phone folder and a NAS folder
- Authentication settings for the NAS (SMB protocol)
- A way to manually sync the files from the app or have them automatically 
sync in the background every 12 hours

{% include carousel_portrait.html height="100" unit="%" duration="7" number="1" %}

The [SMBJ](https://github.com/hierynomus/smbj)
library done a lot of the heavy lifting
in allowing communication between the phone and
the network drive - all that was needed was a background
service to have a timer to run the sync and upload the files.

You can see the result in this [repo](https://github.com/thejester129/nas-sync-android)

Feel free to fork it and adapt it to your needs.

Happy coding!


