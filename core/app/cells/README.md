# Cell Classes

## Introduction

The primary role a cell class is to encapsulate a component of a view.  

## Implementation

* Cells go into the "cells" folder of the main Rails app or of an engine.

* Cells should be named `XXXCell` in a file called `xxx_cell.rb`

* Cells should inherit from `Cell::ViewModel`.

* Cells may have a helper method that calls the cell.  E.g.,:
  ```
  def flash_box(level, text=nil, help_text=nil)
    cell(:flash).(:show, self, level, text, help_text)
  end
  ```

## Legacy notes

Some of the cells that have been ported over from `concertim-emma` are passed
the view context as an explicit argument.  This is likley a hold over from a
prior implementation of Cells.  It can likely be replaced with using
`#controller` in the cell.

## Further reading

The Cells documentation at

* https://github.com/trailblazer/cells
* https://github.com/trailblazer/cells-rails
* https://trailblazer.to/2.1/docs/cells.html#cells-overview
