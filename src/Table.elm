module Table exposing
  ( view
  , config, stringColumn, intColumn, floatColumn
  , State, initialSort
  , Column, customColumn, veryCustomColumn
  , Sorter, unsortable, increasingBy, decreasingBy
  , increasingOrDecreasingBy, decreasingOrIncreasingBy
  , Config, customConfig
  , Customizations, HtmlDetails, Status(..), defaultCustomizations
  )

{-|

This library helps you create sortable tables. The crucial feature is that it
lets you own your data separately and keep it in whatever format is best for
you. This way you are free to change your data without worrying about the table
&ldquo;getting out of sync&rdquo; with the data. Having a single source of
truth is pretty great!

I recommend checking out the [examples][] to get a feel for how it works.

[examples]: https://github.com/evancz/elm-sortable-table/tree/master/examples

# View

@docs view

# Configuration

@docs config, stringColumn, intColumn, floatColumn

# State

@docs State, initialSort


# Crazy Customization

If you are new to this library, you can probably stop reading here. After this
point are a bunch of ways to customize your table further. If it does not
provide what you need, you may just want to write a custom table yourself. It
is not that crazy.

## Custom Columns

@docs Column, customColumn, veryCustomColumn,
  Sorter, unsortable, increasingBy, decreasingBy,
  increasingOrDecreasingBy, decreasingOrIncreasingBy

## Custom Tables

@docs Config, customConfig, Customizations, HtmlDetails, Status,
  defaultCustomizations
-}

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events as E
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2, lazy3)
import Json.Decode as Json



-- STATE


{-| Tracks which column to sort by.
-}
type State =
  State String Bool


{-| Create a table state. By providing a column name, you determine which
column should be used for sorting by default. So if you want your table of
yachts to be sorted by length by default, you might say:

    import Table

    Table.initialSort "Length"
-}
initialSort : String -> State
initialSort header =
  State header False



-- CONFIG


{-| Configuration for your table, describing your columns.

**Note:** Your `Config` should *never* be held in your model.
It should only appear in `view` code.
-}
type Config data msg =
  Config
    { toId : data -> String
    , toMsg : State -> msg
    , columns : List (ColumnData data msg)
    , customizations : Customizations data msg
    }


{-| Create the `Config` for your `view` function. Everything you need to
render your columns efficiently and handle selection of columns.

Say we have a `List Person` that we want to show as a table. The table should
have a column for name and age. We would create a `Config` like this:

    import Table

    type Msg = NewTableState State | ...

    config : Table.Config Person Msg
    config =
      Table.config
        { toId = .name
        , toMsg = NewTableState
        , columns =
            [ Table.stringColumn "Name" .name
            , Table.intColumn "Age" .age
            ]
        }

You provide the following information in your table configuration:

  - `toId` &mdash; turn a `Person` into a unique ID. This lets us use
  [`Html.Keyed`][keyed] under the hood to make resorts faster.
  - `columns` &mdash; specify some columns to show.
  - `toMsg` &mdash; a way send new table states to your app as messages.

See the [examples][] to get a better feel for this!

[keyed]: http://package.elm-lang.org/packages/elm-lang/html/latest/Html-Keyed
[examples]: https://github.com/evancz/elm-sortable-table/tree/master/examples
-}
config
  : { toId : data -> String
    , toMsg : State -> msg
    , columns : List (Column data msg)
    }
  -> Config data msg
config { toId, toMsg, columns } =
  Config
    { toId = toId
    , toMsg = toMsg
    , columns = List.map (\(Column cData) -> cData) columns
    , customizations = defaultCustomizations
    }


{-| Just like `config` but you can specify a bunch of table customizations.
-}
customConfig
  : { toId : data -> String
    , toMsg : State -> msg
    , columns : List (Column data msg)
    , customizations : Customizations data msg
    }
  -> Config data msg
customConfig { toId, toMsg, columns, customizations } =
  Config
    { toId = toId
    , toMsg = toMsg
    , columns = List.map (\(Column cData) -> cData) columns
    , customizations = customizations
    }


{-| There are quite a lot of ways to customize the `<table>` tag. You can add
a `<caption>` which can be styled via CSS. You can do crazy stuff with
`<thead>` to group columns in weird ways. You can have a `<tfoot>` tag for
summaries of various columns. And maybe you want to put attributes on `<tbody>`
or on particular rows in the body. All these customizations are available to you.

**Note:** The level of craziness possible in `<thead>` and `<tfoot>` are so
high that I could not see how to provide the full functionality *and* make it
impossible to do bad stuff. So just be aware of that, and share any stories
you have. Stories make it possible to design better!
-}
type alias Customizations data msg =
  { tableAttrs : List (Attribute msg)
  , caption : Maybe (HtmlDetails msg)
  , thead : List (String, Status, Attribute msg) -> HtmlDetails msg
  , tfoot : Maybe (HtmlDetails msg)
  , tbodyAttrs : List (Attribute msg)
  , rowAttrs : data -> List (Attribute msg)
  }


{-| Sometimes you must use a `<td>` tag, but the attributes and children are up
to you. This type lets you specify all the details of an HTML node except the
tag name.
-}
type alias HtmlDetails msg =
  { attributes : List (Attribute msg)
  , children : List (Html msg)
  }


{-| The customizations used in `config` by default.
-}
defaultCustomizations : Customizations data msg
defaultCustomizations =
  { tableAttrs = []
  , caption = Nothing
  , thead = simpleThead
  , tfoot = Nothing
  , tbodyAttrs = []
  , rowAttrs = simpleRowAttrs
  }


simpleThead : List (String, Status, Attribute msg) -> HtmlDetails msg
simpleThead headers =
  HtmlDetails [] (List.map simpleTheadHelp headers)


simpleTheadHelp : ( String, Status, Attribute msg ) -> Html msg
simpleTheadHelp (name, status, onClick) =
  let
    content =
      case status of
        Unsortable ->
          [ Html.text name ]

        Sortable selected ->
          [ Html.text name
          , if selected then darkGrey "↓" else lightGrey "↓"
          ]

        Reversible Nothing ->
          [ Html.text name
          , lightGrey "↕"
          ]

        Reversible (Just isReversed) ->
          [ Html.text name
          , darkGrey (if isReversed then "↑" else "↓")
          ]
  in
    Html.th [ onClick ] content


darkGrey : String -> Html msg
darkGrey symbol =
  Html.span [ Attr.style [("color", "#555")] ] [ Html.text (" " ++ symbol) ]


lightGrey : String -> Html msg
lightGrey symbol =
  Html.span [ Attr.style [("color", "#ccc")] ] [ Html.text (" " ++ symbol) ]


simpleRowAttrs : data -> List (Attribute msg)
simpleRowAttrs _ =
  []


{-| The status of a particular column, for use in the `thead` field of your
`Customizations`.

  - If the column is unsortable, the status will always be `Unsortable`.
  - If the column can be sorted in one direction, the status will be `Sortable`.
    The associated boolean represents whether this column is selected. So it is
    `True` if the table is currently sorted by this column, and `False` otherwise.
  - If the column can be sorted in either direction, the status will be `Reversible`.
    The associated maybe tells you whether this column is selected. It is
    `Just isReversed` if the table is currently sorted by this column, and
    `Nothing` otherwise. The `isReversed` boolean lets you know which way it
    is sorted.

This information lets you do custom header decorations for each scenario.
-}
type Status
  = Unsortable
  | Sortable Bool
  | Reversible (Maybe Bool)



-- COLUMNS


{-| Describes how to turn `data` into a column in your table.
-}
type Column data msg =
  Column (ColumnData data msg)


type alias ColumnData data msg =
  { name : String
  , viewData : data -> HtmlDetails msg
  , sorter : Sorter data
  }


{-|-}
stringColumn : String -> (data -> String) -> Column data msg
stringColumn name toStr =
  Column
    { name = name
    , viewData = textDetails << toStr
    , sorter = increasingOrDecreasingBy toStr
    }


{-|-}
intColumn : String -> (data -> Int) -> Column data msg
intColumn name toInt =
  Column
    { name = name
    , viewData = textDetails << toString << toInt
    , sorter = increasingOrDecreasingBy toInt
    }


{-|-}
floatColumn : String -> (data -> Float) -> Column data msg
floatColumn name toFloat =
  Column
    { name = name
    , viewData = textDetails << toString << toFloat
    , sorter = increasingOrDecreasingBy toFloat
    }


textDetails : String -> HtmlDetails msg
textDetails str =
  HtmlDetails [] [ Html.text str ]


{-| Perhaps the basic columns are not quite what you want. Maybe you want to
display monetary values in thousands of dollars, and `floatColumn` does not
quite cut it. You could define a custom column like this:

    import Table

    dollarColumn : String -> (data -> Float) -> Column data msg
    dollarColumn name toDollars =
      Table.customColumn
        { name = name
        , viewData = \data -> viewDollars (toDollars data)
        , sorter = Table.decreasingBy toDollars
        }

    viewDollars : Float -> String
    viewDollars dollars =
      "$" ++ toString (round (dollars / 1000)) ++ "k"

The `viewData` field means we will displays the number `12345.67` as `$12k`.

The `sorter` field specifies how the column can be sorted. In `dollarColumn` we
are saying that it can *only* be shown from highest-to-lowest monetary value.
More about sorters soon!
-}
customColumn
  : { name : String
    , viewData : data -> String
    , sorter : Sorter data
    }
  -> Column data msg
customColumn { name, viewData, sorter } =
  Column <|
    ColumnData name (textDetails << viewData) sorter


{-| It is *possible* that you want something crazier than `customColumn`. In
that unlikely scenario, this function lets you have full control over the
attributes and children of each `<td>` cell in this column.

So maybe you want to a dollars column, and the dollar signs should be green.

    import Html exposing (Html, Attribute, span, text)
    import Html.Attributes exposing (style)
    import Table

    dollarColumn : String -> (data -> Float) -> Column data msg
    dollarColumn name toDollars =
      Table.veryCustomColumn
        { name = name
        , viewData = \data -> viewDollars (toDollars data)
        , sorter = Table.decreasingBy toDollars
        }

    viewDollars : Float -> Table.HtmlDetails msg
    viewDollars dollars =
      Table.HtmlDetails []
        [ span [ style [("color","green")] ] [ text "$" ]
        , text (toString (round (dollars / 1000)) ++ "k")
        ]
-}
veryCustomColumn
  : { name : String
    , viewData : data -> HtmlDetails msg
    , sorter : Sorter data
    }
  -> Column data msg
veryCustomColumn =
  Column



-- VIEW


{-| Take a list of data and turn it into a table. The `Config` argument is the
configuration for the table. It describes the columns that we want to show. The
`State` argument describes which column we are sorting by at the moment.

**Note:** The `State` and `List data` should live in your `Model`. The `Config`
for the table belongs in your `view` code. I very strongly recommend against
putting `Config` in your model. Describe any potential table configurations
statically, and look for a different library if you need something crazier than
that.
-}
view : Config data msg -> State -> List data -> Html msg
view (Config { toId, toMsg, columns, customizations }) state data =
  let
    sortedData =
      sort state columns data

    theadDetails =
      customizations.thead (List.map (toHeaderInfo state toMsg) columns)

    thead =
      Html.thead theadDetails.attributes theadDetails.children

    tbody =
      Keyed.node "tbody" customizations.tbodyAttrs <|
        List.map (viewRow toId columns customizations.rowAttrs) sortedData

    withFoot =
      case customizations.tfoot of
        Nothing ->
          tbody :: []

        Just { attributes, children } ->
          Html.tfoot attributes children :: tbody :: []
  in
    Html.table customizations.tableAttrs <|
      case customizations.caption of
        Nothing ->
          thead :: withFoot

        Just { attributes, children } ->
          Html.caption attributes children :: thead :: withFoot


toHeaderInfo : State -> (State -> msg) -> ColumnData data msg -> ( String, Status, Attribute msg )
toHeaderInfo (State sortName isReversed) toMsg { name, sorter } =
  case sorter of
    None ->
      ( name, Unsortable, onClick sortName isReversed toMsg )

    Increasing _ ->
      ( name, Sortable (name == sortName), onClick name False toMsg )

    Decreasing _ ->
      ( name, Sortable (name == sortName), onClick name False toMsg )

    IncOrDec _ ->
      if name == sortName then
        ( name, Reversible (Just isReversed), onClick name (not isReversed) toMsg )
      else
        ( name, Reversible Nothing, onClick name False toMsg )

    DecOrInc _ ->
      if name == sortName then
        ( name, Reversible (Just isReversed), onClick name (not isReversed) toMsg )
      else
        ( name, Reversible Nothing, onClick name False toMsg )


onClick : String -> Bool -> (State -> msg) -> Attribute msg
onClick name isReversed toMsg =
  E.on "click" <| Json.map toMsg <|
    Json.map2 State (Json.succeed name) (Json.succeed isReversed)


viewRow : (data -> String) -> List (ColumnData data msg) -> (data -> List (Attribute msg)) -> data -> ( String, Html msg )
viewRow toId columns toRowAttrs data =
  ( toId data
  , lazy3 viewRowHelp columns toRowAttrs data
  )


viewRowHelp : List (ColumnData data msg) -> (data -> List (Attribute msg)) -> data -> Html msg
viewRowHelp columns toRowAttrs data =
  Html.tr (toRowAttrs data) (List.map (viewCell data) columns)


viewCell : data -> ColumnData data msg -> Html msg
viewCell data {viewData} =
  let
    details =
      viewData data
  in
    Html.td details.attributes details.children



-- SORTING


sort : State -> List (ColumnData data msg) -> List data -> List data
sort (State selectedColumn isReversed) columnData data =
  case findSorter selectedColumn columnData of
    Nothing ->
      data

    Just sorter ->
      applySorter isReversed sorter data


applySorter : Bool -> Sorter data -> List data -> List data
applySorter isReversed sorter data =
  case sorter of
    None ->
      data

    Increasing sort ->
      sort data

    Decreasing sort ->
      List.reverse (sort data)

    IncOrDec sort ->
      if isReversed then List.reverse (sort data) else sort data

    DecOrInc sort ->
      if isReversed then sort data else List.reverse (sort data)


findSorter : String -> List (ColumnData data msg) -> Maybe (Sorter data)
findSorter selectedColumn columnData =
  case columnData of
    [] ->
      Nothing

    {name, sorter} :: remainingColumnData ->
      if name == selectedColumn then
        Just sorter
      else
        findSorter selectedColumn remainingColumnData



-- SORTERS


{-| Specifies a particular way of sorting data.
-}
type Sorter data
  = None
  | Increasing (List data -> List data)
  | Decreasing (List data -> List data)
  | IncOrDec (List data -> List data)
  | DecOrInc (List data -> List data)


{-| A sorter for columns that are unsortable. Maybe you have a column in your
table for delete buttons that delete the row. It would not make any sense to
sort based on that column.
-}
unsortable : Sorter data
unsortable =
  None


{-| Create a sorter that can only display the data in increasing order. If we
want a table of people, sorted alphabetically by name, we would say this:

    sorter : Sorter { a | name : comparable }
    sorter =
      increasingBy .name
-}
increasingBy : (data -> comparable) -> Sorter data
increasingBy toComparable =
  Increasing (List.sortBy toComparable)


{-| Create a sorter that can only display the data in decreasing order. If we
want a table of countries, sorted by population from highest to lowest, we
would say this:

    sorter : Sorter { a | population : comparable }
    sorter =
      decreasingBy .population
-}
decreasingBy : (data -> comparable) -> Sorter data
decreasingBy toComparable =
  Decreasing (List.sortBy toComparable)


{-| Sometimes you want to be able to sort data in increasing *or* decreasing
order. Maybe you have a bunch of data about orange juice, and you want to know
both which has the most sugar, and which has the least sugar. Both interesting!
This function lets you see both, starting with decreasing order.

    sorter : Sorter { a | sugar : comparable }
    sorter =
      decreasingOrIncreasingBy .sugar
-}
decreasingOrIncreasingBy : (data -> comparable) -> Sorter data
decreasingOrIncreasingBy toComparable =
  DecOrInc (List.sortBy toComparable)


{-| Sometimes you want to be able to sort data in increasing *or* decreasing
order. Maybe you have race times for the 100 meter sprint. This function lets
sort by best time by default, but also see the other order.

    sorter : Sorter { a | time : comparable }
    sorter =
      increasingOrDecreasingBy .time
-}
increasingOrDecreasingBy : (data -> comparable) -> Sorter data
increasingOrDecreasingBy toComparable =
  IncOrDec (List.sortBy toComparable)