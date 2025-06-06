---
layout: post
title: Quickest way to mock library classes with Jest
category: dev
description: Easily mock AWS SDK client components and more
thumbnail: /assets/img/posts/dev/jest-mock-classes/jest-thumb.png
tags: node javascript jest testing
---

I was recently refactoring some old lambda code that was still running on Node 8,
which neccessitated an upgrade to the AWS SDK.

The code was defined in-line in a cloudformation file, and therefore had no typing, syntax highlighting, and of course wasn't tested.

As it was working with some important lifecycle events, I decided to do things properly, extract it to a file and unit test it.

I ran into quite a few gotchas and issues mocking the necessary AWS clients - so decided to write down a quick guide as this didn't seem well documented.

## Mocking Classes

I looked up jest [documentation](https://jestjs.io/docs/es6-class-mocks), which amongst more tedious methods,
proposed something like below:

```typescript
// documentation example
const mockPlaySoundFile = jest.fn();
jest.mock('./sound-player', () => {
  return jest.fn().mockImplementation(() => {
    return { playSoundFile: mockPlaySoundFile };
  });
});
```

<br>
I dutifully copied and adapted this implementation, hit run and... 

```bash
    ReferenceError: Cannot access 'mockPlaySoundFile' before initialization
```

I had a closer look at the documentation and

<b>Gotcha No 1:</b> 

<b>"By default, you cannot first define a variable and then use it in the factory. Jest will disable this check for variables that start with the word mock"</b>

<br>
Ok, so my mock functions/variables that I pass into the mock implementation have to start with `mock`
Slightly ugly, but I'm already doing that. So what's the problem?

Jest [hoists](https://developer.mozilla.org/en-US/docs/Glossary/Hoisting) the `jest.mock()`
call to the top of the file, which means any variables inside the mock function have to be already defined.

Since this is impossible to do within the same file and impractical as we may want to change the mock later on in the test code,
the easy workaround is to lazily evaluate the mock variable.

And not forgetting to also include the actual imports for all the other parts of the module that
we aren't explicitly mocking, this gives us the working below result.


## Working Example
```typescript
const mockEcsSend = jest.fn();

jest.mock("@aws-sdk/client-ecs", () => ({
  ...jest.requireActual("@aws-sdk/client-ecs"),
  ECSClient: jest.fn().mockImplementation(() => {
    return { send: () => mockEcsSend() };
  }),
}));
```

This is a quick and simple way to mock the classes of the module we want,
while leaving the rest intact, without additional mock files or other dark wizardry.

We can then set the result of `send()` to whatever we want to satisfy our testing.

```typescript
beforeAll(() => {
    mockEcsSend.mockReturnValue({
        containerInstances: [
            {
                status: "DRAINING",
                runningTasksCount: 0,
            },
        ],
    });
});
```

<br>

Happy coding!


{% include post-footer.html postId="jest-mock-classes" %}
