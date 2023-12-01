# Decorator Classes 


## Introduction

Not to be confused with presenters.

A decorator class is a class that takes an object, and returns the 
same object with some additional bells and whistles added to it. 

There will not be many instances where a decorator class is useful, but 
one such example is in preparing collections for action tables. The 
"building up" of these collections is dynamic based on the type of object
in the collection, and a decorator class is a good place to store the
logic behind this "building up".


## Implementation

* Decorators go into the "decorators" folder of an engine.

* Decorators should be named XXXDecorator, where "XXX" is the name of 
  the model or object the class is decorating.

* Decorators should inherit from Emma::Decorator.

* Decorators are constructed by default with two arguments:
  * The object being decorated (called the "subject")
  * A set of options (optional)

* The developer of the decorator is then responsible for implementing the
  `:decorate_subject!` method. This method should alter `@subject` in the way
  you want to alter it (adding on methods, including modules etc.)

* From a controller, you would then use a decorator like this: 

  ```ruby
    @decorated_foo = FooDecorator.decorate!(@foo, {some_option: true})
  ```



## Further Reading

Implementation heavily inspired by the "Draper" gem. 
https://github.com/drapergem/draper


## Why not draper

Not using "draper" was a concious decision made by some developer of
legacy Concertim. That developer believed it is too intrusive upon how one works
with models in the views. According to them, a developer who see the following
in the view:

```ruby
@device
```

will expect that to be a "device" model, but under draper it will actually
be a "Decorator" object. Confusing.

I (Ben), have continued with this decision so that I can port the
`ActionTableCollectionDecorator` (aka `ResourceTableCollectionDecorator`) from
legacy concertim without also having to port it to draper at the same time.
This may be a decision worth reconsidering.
