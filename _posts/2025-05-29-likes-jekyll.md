---
layout: post
title: Add post likes to a Jekyll site
category: dev
description: With minimal effort
thumbnail: /assets/img/posts/likes-jekyll/thumb.png
image: /assets/img/posts/likes-jekyll/thumb.png
tags: jekyll how-to javascript
---

So you've created your static website with [Jekyll](https://jekyllrb.com/)
and all your posts are looking beautiful.
But now you wish you had a way to track user interaction with the website:
likes, comments, page view counts etc

I'll break the above components into several articles
to allow more focus with this article going over <b>post likes.</b>
If you're interested in <b>view counts</b> checkout out 
[this](/posts/view-count-jekyll) article - it follows much the same format.

## <ins>Back End</ins>

Ok, so you do need a back end. Your static website needs to have
a place to store the likes, and it's slightly horrible to have 
to store that in the static assets themselves.
But I promise you don't need a lot of code or be an experienced developer
to get this done.

I've used `AWS` since they offer a generous free tier
and it's very easy to get a quick back end off the ground.

I went for an `API Gateway` => `Lambda` => `DynamoDB` architecture.

#### Database
First you'll need a place to store the data.
If you use AWS, `DynamoDB` is the simplest place to do this.

Go to the DynamoDB page in the AWS Console, create a new table,
use `postId` as the primary key and leave the other settings as default.

Well done! You have a table.

#### Handler

Then you'll need some logic to write to the database.
You'll need a handler to get the number of likes for the current page
and one for adding a new like when a user click the button.
`AWS Lambda` is the simplest way to handle both.

Create a new Lambda using the DDB blueprint, I
used Node 18 for my function.

In your function you'll want to parse the postId
we'll be passing to the api in the route (more on that later)
and then getting the item from the database.
If there is no entry yet,
we want to add and return a default one with 0 likes.

```javascript
const postId = event.pathParameters.postId; 

// ... template code

case 'GET':
    command = new GetCommand({
        TableName: tableName,
        Key: {
            postId: postId,
        },
    });

    response = await docClient.send(command);

    body = response.Item;

    if (!body) {
        body = {
            postId: postId,
            likes: 0
        }
        command = new PutCommand({
            TableName: tableName,
            Item: {
                postId: postId,
                likes: 0
            },
        });

        await docClient.send(command);
    }

```

And do something similar for adding 1 to the like count

```javascript
case 'PUT':
    command = new UpdateCommand({
        TableName: tableName,
        Key: {
            postId: postId
        },
        UpdateExpression: "set #likes = #likes + :likes",
        ExpressionAttributeNames: {
            "#likes": "likes"
        },
        ExpressionAttributeValues: {
            ":likes": 1,
        },
        ReturnValues: "ALL_NEW",
    });
    
    response = await docClient.send(command);
    break;
```


#### API Gateway

And now for the gateway to connect the API calls to our handler.

I went for a REST Api Gateway since it's very fitting for this purpose.

Create a REST Api Gateway with default settings and add your methods
like below, integrating the GET and PUT requests to our lambda function from above.

```yaml
/likes:
  /{postId}
    -GET
    -PUT
```

Make sure you add a 
`"Access-Control-Allow-Origin":"*"`
response header somewhere, either in your lambda or the API gateway,
otherwise the browser will not let the request through.

Make sure to deploy your api gateway to a stage after making all the changes
and you're all set!
Test your api with `Postman` or doing a curl

```bash
curl https://my-awesome-api.execute-api.eu-west-1.amazonaws.com/prod/likes/1
```

## <ins>Front End</ins>

The below is enough for a simple Jekyll UI element you can re-use
in your posts.

This section creates an html element to display the likes,
fetches the number of likes from the database and populates
the element.

```html
<div
  style="cursor: pointer; user-select: none; -webkit-user-select: none"
  id="like-button"
>
  <i id="like-icon" style="margin-right: 10px" class="fa fa-thumbs-up"></i>
  <span id="like-count"> </span>
  Likes
  <script>
    // get likes
    const postId = "{{ include.postId }}";
    fetch(
      `https://your-awesome-api/likes/${postId}` // TODO
    )
      .then((response) => response.json())
      .then((data) => {
        document.querySelector("#like-count").textContent = data.likes;
      })
      .catch((error) => {
        console.error("Error fetching likes:", error);
      });
  </script>
</div>
```


This section adds a handler to the like button
to push a new like.

```javascript
document
      .querySelector("#like-button")
      .addEventListener("click", function () {
        if (likedPosts.includes(postId)) {
          return;
        }
        likedPosts.push(postId);
        setCookie("likedPosts", JSON.stringify(likedPosts), 365);
        likeIcon.style.color = "#fc0362";

        const likeCount =
          parseInt(document.querySelector("#like-count").textContent) || 0;
        document.querySelector("#like-count").textContent = likeCount + 1;

        fetch(
          `https://your-awesome-api/likes/${postId}`, // TODO
          {
            method: "PUT",
          }
        ).then((response) => {
          if (!response.ok) {
            console.log(response);
          }
        });
      });
```


You can improve this by adding a cookie to track
unique users (and add nice colors!). 

Use the `setCookie` and `getCookie` methods from this
[tutorial](https://www.w3schools.com/js/js_cookies.asp)
and add the following code

```javascript
// load storage
const storedLikedPosts = getCookie("likedPosts");
let likedPosts = [];
if (!!storedLikedPosts || storedLikedPosts !== "") {
    likedPosts = JSON.parse(storedLikedPosts);
}
if (likedPosts.includes(postId)) {
    likeIcon.style.color = "#fc0362";
}
```

You can then check whether a user has likes a post
previously and stop them from doing it more than once.

You'll need to pass a `postId` variable to your template.
For my case I've created a `post-footer.html` file where I included
the above template
(calling it `footer.html` creates a conflict with a built-in template!)
in the `_layouts` folder
that I can then include in every post 
```
{
    % include post-footer.html postId="my-awesome-post" %
}
```

Check out the full code [here](https://github.com/thejester129/andrewhollis.co.uk/blob/main/_includes/likes.html)

<b>Happy coding!</b>

{% include post-footer.html postId="likes-jekyll" %}
