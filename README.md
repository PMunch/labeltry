# Labeled exceptions
This is a small package/experiment to deal with exceptions a bit more
ergonomically. Unlike things like wrapping exceptions in an optional Result type
this is designed to not interfere with the regular control flow. The idea is
that while libraries can define _why_ something went wrong with exceptions, they
don't really allow us to filter on _what_ went wrong. The traditional motiving
example is something like a traditional web flow:

```nim
let user = try:
  getUser(userInfo)
except CatchableError as e:
  echo "Cannot get user: " & e.msg
  return %*{"error": "Cannot get user " & userInfo.name}
let news = try:
  getNewsForUser(user.id)
except CatchableError as e:
  echo "Cannot get news for user: " & e.msg
  return %*{"error": "Cannot get news for user " & userInfo.name}
let relatedNews = try:
  getRelatedNews(news)
except CatchableError as e:
  echo "Cannot get related news for user: " & e.msg
  return %*{"error": "Cannot get related news for user " & userInfo.name}
return %*{"data": {"news": news.value, "relatedNews": relatedNews.value}}
```

Here we have three actions which simply do three actions and use the results
from the past actions while giving fine-grained error messages. This however
obscures the actual logic in all the error handling. The alternative is to just
have everything in one big try/except and end up with coarse error messages.
With labeled exceptions however the programmer can throw in some extra
information that allows them to identify the exception later on. This adds the
crucial "_what_ went wrong" information we need to decouple the exceptions from
the application code:

```nim
labeledTry:
  let
    user = getUser(userInfo) |> User
    news = getNewsForUser(user.id) |> News
    relatedNews = getRelatedNews(news) |> Related
  return %*{"data": {"news": news.value, "relatedNews": relatedNews.value}}
except CatchableError as e:
  let error = "Cannot get " &
    case getLabel():
    of User: "user " & userInfo.name
    of News: "news for user " & userInfo.name
    of Related: "related news for user " & userInfo.name
    of NoLabel: "<unknown>" # exception thrown without label
  echo error & ": " & e.msg
  return %*{"error": error}
```

This shows us doing the same three things, but labeling each one with an
identifier. We then have one common exception handler which despite all the
errors being the same exception type can distinguish between where in our code
the exception came from. The label is created as an enum, so with a case
statement you are guaranteed by Nim that all the cases are covered and that you
can't have cases for labels which don't exist. It is also possible to use a
block statement to label all exceptions from a block of code. And as an added
bonus these labels are available in the `finally` branch so you can also know
which parts of your code requires cleanup:

```nim
labeledTry:
  let user = getUser(userInfo) |> User
  label(News):
    let
      news = getNewsForUser(user.id)
      relatedNews = getRelatedNews(news)
    return %*{"data": {"news": news.value, "relatedNews": relatedNews.value}}
except CatchableError as e:
  let error = "Cannot get " &
    case getLabel():
    of User: "user " & userInfo.name
    of News: "news for user " & userInfo.name
    of NoLabel: "<unknown>" # exception thrown without label
  echo error & ": " & e.msg
  return %*{"error": error}
finally:
  if getLabel() != NoLabel:
    echo "A Labeled exception was thrown in our code!"
```

This has mostly been an experiment to see what is possible with exceptions and
how flexible Nim macros can be. The language is really well suited for this
kind of small experiments where you can play around with language ideas purely
within your own code. Whether this model of exception handling is actually
useful or not depends to be seen.
