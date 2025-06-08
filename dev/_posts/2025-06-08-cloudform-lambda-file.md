---
layout: post
title: Cloudform Lambda functions from file without Zip packages
category: dev
description: 
thumbnail: /assets/img/posts/dev/cloudform-lambda-file/cloudform-lambda-file-thumb.png
tags: aws lambda cloudformation bash how-to
---

Do you like the convenience of defining a lambda function inline in your cloudformation to avoid the hassle of uploading and referencing a zip file
but miss syntax highlighting, being able to update and test the function in a sane way?
I ran into the same problem and realised there is a nice middle ground that is less documented.

<br>
<b>TLDR: define your function in a separate file and use a cloudformation parameter to pass it in!</b>

## Step 1: Define lambda function in a separate file

This should be the obvious first step. We want our function in a separate file,
so our editor can give us nice syntax highlighting, autocomplete and we are able to unit test the function
if we choose to do so.

We'll define a minimal NodeJS lambda function in a file called `index.js`

```js
exports.handler = function (event, context) {
  console.log("Hello aws!");
};
```

## Step 2: Read file contents into bash variable

We want to pass the contents of the file as a variable into the cloudformation template.
So we need to get the contents of a file as a string variable and pass it in as a parameter override.

If using bash, you can do so like below (`cat` works as well, `<` is however a built-in function so it's more portable).

```bash
lambda_src=$(< index.js)
```

Bash variables have a basically [unlimited](https://stackoverflow.com/questions/5076283/shell-variable-capacity)
size capacity, so the length of the file shouldn't pose an issue for this step.

### Step 3: Pass source in variable as stack parameter
Next we'll need to pass our file-as-string variable into the cloudformation template.
This is where we do run into a stricter limit - cloudformation template parameters
have a max size of [4KB](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html)

This is roughly equivalent to `150 lines` of NodeJS code - so it's definitely not the best
solution for longer functions but perfect for medium sized ones that aren't trivial enough
to just be inline. You can use a site like [Byte Size Matters](https://bytesizematters.com/)
to check the byte size of the file.

We can pass in our variable defined in step 3 into `parameter-overrides` - 
make sure to wrap it in quotes so bash doesn't complain.

```bash
aws cloudformation deploy \
    --stack-name lambda-inline-file \
    --template-file ./cloudformation.yml \
    --parameter-overrides LambdaSrc="$lambda_src" \
    --capabilities=CAPABILITY_IAM 
```

### Step 4: Pass parameter into ZipFile config 
Next we'll want to create our cloudformation file and ensure we pass
the parameter defined above into the `ZipFile` config value.

```yml
AWSTemplateFormatVersion: '2010-09-09'

Parameters:
  LambdaSrc:
    Type: String

Resources:
  LambdaFn:
    Type: AWS::Lambda::Function
    Properties:
      Handler: index.handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: !Ref LambdaSrc
      Runtime: nodejs20.x

  # lambda execution role
  # ...
```

And we're done!

Deploy the cloudformation file and we'll see our lambda code has updated correctly.

![](/assets/img/posts/dev/cloudform-lambda-file/cloudformation-lambda-working.png)
_AWS Console_

You can see the full repo [here](https://github.com/thejester129/cloudform-lambda-inline-file)

<br>
<b>Happy coding!</b>

{% include post-footer.html postId="cloudform-lambda-file" %}
