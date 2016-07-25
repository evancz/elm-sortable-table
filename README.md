# Sortable Tables

Create sortable tables for data of any shape.

This library also lets you customize `<caption>`, `<tbody>`, `<tr>`, etc. for your particular needs. So it is pretty easy to do whatever crazy CSS trickery is needed to get the exact table you want.


## Examples

  1. [U.S. Presidents by Birth Place](https://evancz.github.io/elm-sortable-table/presidents.html) / [Code](https://github.com/evancz/elm-sortable-table/blob/master/examples/1-presidents.elm)
  2. [Travel Planner for the Mission District in San Francisco](https://evancz.github.io/elm-sortable-table/travel.html) / [Code](https://github.com/evancz/elm-sortable-table/blob/master/examples/2-travel.elm)


## Usage Rules

  - Always put `Table.State` in your model.
  - Never put `Table.Config` in your model.

One of the core rules of The Elm Architecture is **never put functions in your `Model` or `Msg` types**. It may cost a little bit of extra code to model everything as data, but the architecture and debugging benefits are worth it. Point is, a `Table.Config` value is really just a bunch of `view` functions, so it does not belong in your model. It goes in your `view`!

Furthermore, you do not want to be creating table configurations dynamically, partly because it is harder to optimize. If you need multiple table configurations, it is best to create multiple top-level definitions and switch between them in your `view` based on other data in your `Model`. If your use case is so complex that this is not possible, please open an issue explaining your situation!


## About API Design

This library is one of the first &ldquo;reusable view&rdquo; packages that also manages some state, so I want to point out some design considerations that will be helpful in general.


### The Elm Architecture

It may not be obvious at first glance, but this library follows The Elm Architecture:

  - `Model` &mdash; There is a model named `Table.State`.

  - `init` &mdash; You initialize the model with `Table.initialSort`.

  - `view` &mdash; You turn the current state into HTML with `Table.view`.

  - `update` &mdash; This is a little hidden, but it is there. When you create a `Table.Config`, you provide a function `Table.State -> msg` so that whoever is rendering the table has a chance to update the table state.

I took some minor liberties with `update` to make the API a bit simpler. It would be more legit if `Table.Config` took a `Table.Msg -> msg` argument and you needed to use `Table.update : Table.Msg -> Table.State -> Table.State` to deal with it. I decided not to go this route because `Table.Msg` and `Table.State` would both allocate the same amount of memory and one version the overall API a bit tougher. As we learn from how people use this, we may see that the explicit `update` function is actually a better way to go though!


### Single Source of Truth

The data displayed by in the table is given as an argument to `view`. To put that another way, the `Table.State` value only tracks the details specific to *displaying* a sorted table, not the actual data to appear in the table. **This is the most important decision in this whole library.** This choice means you can change your data without any risk of the table getting out of sync. You may be adding things, changing entries, or whatever else; the table will never &ldquo;get stuck&rdquo; and display out of date information.

To make this more clear, let&rsquo;s imagine the alternate choice: instead of giving `List data` to `view`, we have it live in `Table.State`. Now say we want to update the dataset. We grab a copy of the data, make the changes we want, and put it back. But what if we forget to put it back? What if we hold on to that second copy in our `Model`? Which one is the *real* data now?

Point is, **when creating an API like this, own as little state as possible.** Having multiple copies of &ldquo;the same&rdquo; value in your `Model` is a sure way to create synchronization errors. Elm is built on the idea that there should be a single source of truth, but if you design your API poorly, you can force your users to make duplicates and open themselves up to bugs for no reason. Do not do that to them!


### Simple By Default

I designed this library to have a very smooth learning curve. As you read the docs, you start with the simplest functions. Predefined columns, and very little customization. This makes it easier for the reader to build a basic intuition for how things work.

The trick is that all these simple functions are defined in terms of crazier ones that allow for more customization. As the user **NEEDS** that complexity, they can read on and gradually use the parts that are relevant to them. This means the user never finds themselves in a situation where they have to learn a bunch of stuff that does not actually matter to them. At the same time, that stuff is there when they need it.

To turn this into advice about API design, **helper functions can make a library simpler to learn and use.** Ultimately, people may not use `Table.floatColumn` very often in real stuff, but that function is crucial for learning. So when you find yourself with a tough API, one way to ramp people up is to create specialized helper functions that let you get common functionality without confronting people with all the details.