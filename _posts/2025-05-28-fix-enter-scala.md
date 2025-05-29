---
layout: post
title: How to fix Enter key printing ^M in terminal
category: dev
description: On a Scala REPL or other places
thumbnail: /assets/img/posts/fix-enter-scala/thumb.png
tags: iterm scala how-to-fix
---

I ran into an issue when playing around with [Scala](https://github.com/thejester129/monkey-interpreter-scala){:target="_blank"}
and trying to get user input working on the terminal.
It was picking up all my keypresses but whenever I pressed the `Enter` key
it would just print `^M`

<br>
![](/assets/img/posts/fix-enter-scala/error.png)
_Error Message_
<br>


<b>Problem:</b>
- Terminal is sending `\r` instead of `\n` to terminate a line. 
`^M` is the ASCII representation of a carriage return, so its printing that instead of going to a new line.

<b>Solution:</b>

I had this problem on `iTerm` but not the default Mac terminal, which pinned this problem to the emulator.

The solution was to change the iTerm setting to send a `\n` instead of `\r` to terminate commands.

You can find this setting under Profiles -> Terminal or search for it in search bar.

<br>
![](/assets/img/posts/fix-enter-scala/setting.png)
_iTerm Setting_
<br>


Other terminal emulators should have a similar setting to fix this issue.

Restart the terminal and test it once again

<br>
![](/assets/img/posts/fix-enter-scala/working.png)
_Woo Hoo_
<br>



Happy coding!


{% include footer.html postId="fix-enter-scala" %}