# Presenter Classes

## Introduction

The primary role of a presenter class is to simplify view logic.

They provide a wrapper for an existing object (typically, but not always, 
active record models) and provide additional methods.

Suppose you had the following logic in your view to render a device title:

```ruby
<%= device.rack ? "Device #{device.name} of rack #{device.rack.name}" : "Device #{device.name}"  %>
```

It's not very neat, and you've encoded that knowledge in a single place, 
what if you need to use it in other places? What if other types of device 
need to use that same type of logic? You will end up:

  * Copy/pasting it all over the application?
  * Putting it in a helper?  (ick)
  * Putting it in the model? (double ick)

No - use a presenter!


## Implementation

* Presenters go into the "presenters" folder of an engine.

* Presenters should be named XXXPresenter, where "XXX" is the name of 
  the model they are presenting.

* Presenters should inherit from Presenter.

* Presenters are constructed by default with two arguments:
  * The object being presented
  * The view context (so you have access to helpers etc.)

* From a controller, you would construct a presenter like this: 

  ```ruby
  @foo_presenter = FooPresenter.new(@foo, view_context)
  ```
  Then in the views:
  ```ruby
  @foo_presenter.title
  ```

* A helper method also exists for constructing presenters from the views:
  ```ruby
  presenter_for(@foo) do |foo_presenter| 
    foo_presenter.title
  end
  ```


* Within a presenter you have access to two "convenience methods" called "o" and "h".
  * o: is a reference to the presented object
  * h: is a reference to the view context (or "helpers", for accessing link_to etc.)
  * Why use "o" and "h"? Because that's what draper uses and it's short/sweet/standard.



## Further Reading

* Implementation heavily inspired by Railscast #287 by Ryan Bates
http://railscasts.com/episodes/287-presenters-from-scratch?view=asciicast

* Implementation also heavily inspired by the "draper" gem:
https://github.com/drapergem/draper
