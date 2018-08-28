# Examples

  1. [U.S. Presidents by Birth Place](https://billstclair.github.io/elm-sortable-table/presidents.html)
  2. [Travel Planner for the Mission District in San Francisco](https://billstclair.github.io/elm-sortable-table/travel.html)


## Build Instructions

To see the examples *without* CSS, run the following commands:

```bash
git clone https://github.com/billstclair/elm-sortable-table.git
cd elm-sortable-table
cd examples
elm-reactor
```

Then navigate to `1-presidents.elm` or `2-travel.elm` from [localhost:8000](http://localhost:8000/). When using `elm-reactor`, refreshing a page that ends with `.elm` will recompile the code in that file and show you the new result.


## Build Instructions with CSS

To see the examples *with* CSS, run the following commands:

```bash
git clone https://github.com/billstclair/elm-sortable-table.git
cd elm-sortable-table
cd examples
elm make 1-presidents.elm --output=site/presidents.js
elm-reactor
```

Then open [localhost:8000/site/presidents.html](http://localhost:8000/site/presidents.html) in your browser. That HTML file loads in some CSS and whatever code is in `presidents.js`.

If you want to see the second example with CSS, you can compile it like this:

```bash
elm make 2-travel.elm --output=site/travel.js
```

And then open [localhost:8000/site/travel.html](http://localhost:8000/site/travel.html).

As you make changes, you will want to recompile the Elm code with `elm-make`.
