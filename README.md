# Typeahead

Typeahead for SaxonJS.

Typeahead is the wellknown phenonemon where suggestions pop up when you are typing text into a text box
on a web page. This functionality is usually programmed with a combination of Javascript and CSS.

The HTML markup for this typeahead is simple: for each textbox, simply insert the following into your HTML
code:

```
<input name="some-name" type="text" data-typeahead=""><span></span>
```

The code in this repository attempts to do the same as the Javascript ones, but now with XSLT (SaxonJS)
and CSS. It has been written in such a way that it is easy to define your own special behaviour. Apart
from making your own beautiful CSS definitions, behaviour can be defined by means of `<xsl:import>` and by
assigning your own values to a `data-typeahead` attribute.

Have a look at the [example.html](example.html) and [example.xslt](xslt/example.xslt) files that come
with this software.

At a minimum, you should redefine the function **typeahead:calculate-items**, which retrieves the items
that should pop up when users start typing.

You may want to assign different values for the `data-typeahead` attribute of each `<input>`. By retrieving
these values in your specialized **typeahead:calculate-items** function, your script can decide which
values to return, for instance trees or animals (as in the provided example). The value you specify in the
`data-typeahead` attribute are propagated in XSLT to the HTML elements (`<ul>` and `<li>`) that are
generated in order to display the list with typeahead options. This makes it convenient to define the
appropriate CSS rules or to use them in your own XSLT constructs.
       
You may want to redefine other functions and templates as well; the most likely function is the function
**typeahead:render-items**, whose contract is that it should render the items returned by
**typeahead:calculate-items** as a HTML list (`<ul>` and `<li>`, as said above). The content of the
`<li>` element will usually be text, but it can be more complex. It can, for instance, also contain span
elements, some of which may contain extra information. However, the content of the list item should be such
that it is possible to redefine the function **typeahead:get-value-from-li** to retrieve the value that
eventually should come in the textfield.

Many functions and templates have an extra parameter, called `anything`. Its value is passed along
when other functions or templates are called. The software does not do anything with this parameter,
but you may want to use it to pass some extra information to the functions that you redefine (in case
you need more parameters, use a map, a sequence or even an array).
       
The stylesheet operates on HTML `<input>` elements with an attribute named `data-typeahead` (whose name can
be overridden in the unlikely case that you already use it for other purposes). Immediately following the `<input>`
element, there should be an empty HTML `<span>` element. There should nothing be in
between the `<input>` and the `<span>` - not even comments, whitespace or processing instructions.

The `<span>` element does not need to have any attributes, but you will probably need to have something that
identifies it for CSS rules. You may want to use a class attribute, but you could also use the
same `data-typeahead` attribute as the `<input>` (although there are no effects connected to it.

**Important:** Do not use the `style` attribute for the `<span>` element, because the stylesheet clears the `style` attribute when the popup is removed from the view.

In addition to the redefinition of some templates or functions, you will need to provide CSS styling sothat
your popup looks nice.
Apart from nicety, following properties are elementary or at least important:

- The `<span>` element should have, in CSS, the property `display: none`, because otherwise it may somehow show up when you
 don't want it. XSLT will display it when needed.
- The `<span>` element should have a background color. Without it, the HTML content below the popup whould remain visible.
- An alternative rendition for typeahead `<li>` items when the mouse hovers above it.
- An alternative rendition for typeahead  `<li>` items when selected by arrow key presses.

Refer to the example styleing (in less-format or the generated CSS-format) for more properties.