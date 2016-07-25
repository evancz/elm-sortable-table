# Examples

  1. [U.S. Presidents by Birth Place](https://evancz.github.io/elm-sortable-table/presidents.html)
  2. [Travel Planner for the Mission District in San Francisco](https://evancz.github.io/elm-sortable-table/travel.html)


## Build Instructions

To see the examples *without* CSS, run the following commands:

```bash
git clone https://github.com/evancz/elm-sortable-table.git
cd elm-sortable-table
cd examples
elm-reactor
```

Then navigate to `1-presidents.elm` or `2-travel.elm` from [localhost:8000](http://localhost:8000/). When using `elm-reactor`, refreshing a page that ends with `.elm` will recompile the code in that file and show you the new result.


## Build Instructions with CSS

To see the examples *with* CSS, run the following commands:

```bash
git clone https://github.com/evancz/elm-sortable-table.git
cd elm-sortable-table
cd examples
elm-make 1-presidents.elm --yes --output=elm.js
elm-reactor
```

Then open [localhost:8000/index.html](http://localhost:8000/index.html) in your browser. That HTML file loads in some CSS and whatever code is in `elm.js`. So if you want to see the second example with CSS, you can compile it like this:

```bash
elm-make 2-travel.elm --yes --output=elm.js
```

As you make changes, you will want to recompile the Elm code with `elm-make`.