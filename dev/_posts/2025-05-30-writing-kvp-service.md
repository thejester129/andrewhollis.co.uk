---
layout: post
title: "Language Comparison: Writing a Rest API Generic Model Store"
category: dev
description: Benchmarking C#, Go, Node & Python
image: /assets/img/posts/kvp-service-comparison/thumb.png
thumbnail: /assets/img/posts/kvp-service-comparison/thumb.png
tags: c# go node python api dynamodb comparison
# pin: true TODO
---

Recently at work I was working on a project to write an API service
that could act as a cloud key-value store and handle generic models that
our different apps may want to use. 

For example:

#### Storing new items, indexed by key
```sh
POST https://my-api.com/user123/user-preferences
{
    "layout": "grid",
    "sortOrder": "descending"
}
```

#### Getting items from store
```sh
GET https://my-api.com/user123/user-preferences
{
    "layout": "grid",
    "sortOrder": "descending"
}
```

#### Updating individual keys
```sh
PATCH https://my-api.com/user123/user-preferences
{
    "sortOrder": "ascending"
}
```

#### Adding new keys
```sh
PATCH https://my-api.com/user123/user-preferences
{
    "darkMode": true
}
```

This seems simple enough but we wanted to allow API clients from various teams to define and evolve
their data models without us having to change server code, so having 
flexible json payloads was a necessary requirement which made things rather tricky.

Our go-to language was C#, which is great for having script types and well defined models
but is rather a pain to deal with when it comes to dynamic json.
Each layer of json has to be accessed by string key and painfully cast to the correct type manually - just check out
the below sample from the official newtonsoft [docs](https://www.newtonsoft.com/json/help/html/modifyjson.htm)

```cs
JObject rss = JObject.Parse(json);

JObject channel = (JObject)rss["channel"];

channel["title"] = ((string)channel["title"]).ToUpper();
channel["description"] = ((string)channel["description"]).ToUpper();

channel.Property("obsolete").Remove();

channel.Property("description").AddAfterSelf(new JProperty("new", "New value"));

JArray item = (JArray)channel["item"];
item.Add("Item 1");
item.Add("Item 2");
```


This got me wondering how simple this task is in other languages...surely this is a common use case?

## The Comparison

I decided to implement the same server in a variety of popular server-side languages, 
to see how easy it was and also benchmark their performance.
It was interesting to me that a language that was made for the web (`.NET` framework!)
was so poor at handling json - I wanted to see if others do it better.

I decided to choose some common languages that each represent a particular branch
of server side programming
- <b>C#</b>: Java-like, compiled, statically typed
- <b>Go</b>: C-like, compiled, statically typed but more flexible
- <b>Node</b>: Ever popular, great JSON handling, optional typing
- <b>Python</b>: Script-like, easy to write, interpreted, dynamic typing

### C#

<ins>Pros:</ins>
- Great when types are known
- Lots of language features for safe and readable code

<ins>Cons:</ins>
- Worst at handling dynamic types
- Most code verbose
- Slow startup time if using in serverless environment

The original project was of course written in C#.
C# is a language compiled to run on a Common Language Runtime (similar to
the JVM) so it works similar to languages like Java, Kotlin and Scala
when it comes to constructing objects from json and manipulating them.

Truth be told, JSON handling in C# doesn't have to be as complicated
as the above example showed, but it's really not well documented
and you get the feel like it's not the kind of thing the language
was made for.

It's possible to leverage `ExpandoObjects` (object which can have
fields added at runtime) and `dynamic` (type which ignores static
type checks) to coerce a string into a dynamic object and even
assign some fields, but it's really not the nicest of experiences.

```cs
string body;
using (var reader = new StreamReader(context.Request.Body))
    body = await reader.ReadToEndAsync();

if (string.IsNullOrEmpty(body))
{
    return null;
}

dynamic? model = JsonConvert.DeserializeObject<ExpandoObject>(body, Service.jsonSettings);
```

If you try assigning values to fields that aren't populated in a dynamic
object you'll get hit with a lovely runtime error, and in general
it's not a super well supported feature of the language with lots of quirks.
Seeing how nicely the other languages handle this problem,
it's a hard sell to go down this route.

### Go

<ins>Pros:</ins>
- Fast
- Simple to write
- Great tooling

<ins>Cons:</ins>
- Can be a bit simplistic with language features

I haven't written a lot of Go in the past,
so I was curious how well it would handle dynamic json.
I got excited when I saw Go has a `interface{}` (or `any`)
type which you can assign to dynamic objects.

All I had to do was create a new type to give to these dynamic
payloads (go thankfully also uses dictionaries to represent
parsed json) and the job was mostly done.

```go
type JsonItem map[string]any
```

Updating fields still required string dictionary keys,
but everything just worked the way it felt like it should
without any quirks or strange corner cases.

```go
var patchItem JsonItem

if err := c.BindJSON(&patchItem); err != nil {
    c.JSON(http.StatusInternalServerError, err.Error())
    return
}

patchItem["key"] = key
updated, err := updateTableItem(c, patchItem)
```

Built in json serialization/deserialization,
method extensions, a json document representation
that made sense...it was easy to make assumptions 
and not be stumped even with a language I wasn't overly familiar with.

Patching an item was rather verbose compared to the other languages,
but with Co-Pilot autocomplete and Go's idiomatic methodology
of not overcomplicating things it still made sense and worked
the way I expected it to.

```go
if err != nil {
    log.Printf("Couldn't build expression for update. Here's why: %v\n", err)
} else {
    response, err = client.UpdateItem(ctx, &dynamodb.UpdateItemInput{
        TableName:                 aws.String(tableName),
        Key:                       map[string]types.AttributeValue{"key": &types.AttributeValueMemberS{Value: item["key"].(string)}},
        ExpressionAttributeNames:  expr.Names(),
        ExpressionAttributeValues: expr.Values(),
        UpdateExpression:          expr.Update(),
        ReturnValues:              types.ReturnValueAllNew,
    })
    if err != nil {
        log.Printf("Couldn't update item: %v\n", err)
    } else {
        err = attributevalue.UnmarshalMap(response.Attributes, &updatedItem)
        if err != nil {
            log.Printf("Couldn't unmarshall update response. Here's why: %v\n", err)
        }
    }
}
```

### Node

<ins>Pros:</ins>
- Flexible typing system (w/ Typescript)
- Great for JSON handling
- Popular therefore lots of packages/libraries

<ins>Cons:</ins>
- Performance

Node's real strength when it comes to backend is
the ease with which it can type and manipulate arbitrary
json objects.

Patch an object?
```js
{ ...object, key: 1 }
```
Clone an object?
```js
const newObject = { ...object };
```

This makes it very fast and convinient to work with
json data and unlike python we can also
give these objects types for some improved
safety and highlighting when working with them.
Typescripts type system is incredibly flexible and
you can usually define exactly what you need to as 
well as an escape hatch when you don't want to be blocked by it.

```ts
const a: User & { extraField: string } = body;
const b = body.extraField; // b is a string
body.unknownValue // compile error
```

With Node 24.0, you can now write Typescript without an extra build step,
which solved a long standing gripe with complicated build systems
needed for it. While performance-wise it's not on par with some
of the other languages, it makes a great option for new or front-end
developers writing back-end services.

### Python

<ins>Pros:</ins>
- Quick and simple to write and run
- Good JSON handling
- Great tooling

<ins>Cons:</ins>
- Weak typing
- Scales less well for big projects

I always love writing python. It feels so good
to `touch` open a new python file and have an http client
hammering requests or a full REST server up in a few lines of code.
No curly braces, no `public static void main`, just straight to the point.

For this API I went for a simple `Flask` server, using 
[Waitress](https://flask.palletsprojects.com/en/stable/deploying/waitress/)
to serve it, since this is a pretty popular combination you're likely to
run into for an adhoc service.
There's probably more performant options out there, but God was
this fast to get up and running.
In less than `60` lines of code, I had a full CRUD service
talking to a dynamodb client.

And pythons representation of json objects as dictionaries came in handy -
I could pass the body object of the request straight into dynamodb
with no additional handling. Simple!

```py
@app.route("/<key>", methods=['PUT'])
def put(key):
    body = request.json
    body['key'] = key
    res = put_item(body)

#...

def put_item(item):
    response = table.put_item(
                Item=item
    ) 
    if 'ResponseMetadata' in response and response['ResponseMetadata']['HTTPStatusCode'] == 200: 
        return item
    return None
```


## Benchmarking

And these are the benchmarks at the end.
This could probably have been done in a more
robust way by running the server in a production
environment on a different machine but the focus of this
experiment has been more on the tooling and how well these languages
handle dynamic json - a performance test was more for fun.

Below are average response times, after serving 10000 requests.
I used a simple python script for this similar to below:

```py
start = time.time()

for i in range(no_of_items):
    res = requests.get(f'http://localhost:8080/{i}')
    if res.status_code != 200:
        print("get request failed")
        exit(1)

end = time.time()

get_time_total = end - start
```

#### C#
```
PUT average time per request:
6.13 ms

GET average time per request:
4.15 ms
```

#### Go
```
PUT average time per request:
6.12 ms

GET average time per request:
4.38 ms
```

#### Node
```
PUT average time per request:
6.47 ms

GET average time per request:
4.77 ms
```

#### Python
```
PUT average time per request:
6.52 ms

GET average time per request:
4.82 ms
```

C# does surprisingly well - maybe it wasn't a waste of time
implementing the server in that!

Python and Node are expectedly a bit slower than the compiled
variants but this of course is just an indication,
as results can vary with different libraries, runtimes and optimisations.

I hope this has been informative. It's always interesting
to see how you can do the same thing in different languages
so you have a better idea of which tool to reach for for which
job!

Check out the full project [here](https://github.com/thejester129/kvp-service-comparison)

<b>Thank you for reading!</b>

{% include post-footer.html postId="kvp-service-comparison" %}
