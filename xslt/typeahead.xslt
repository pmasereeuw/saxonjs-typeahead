<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:typeahead="http://www.masereeuw.nl/namespaces/typeahead"
  exclude-result-prefixes="#all"
  extension-element-prefixes="ixsl"
  expand-text="yes"
  version="3.0">
  
  <!-- (Copied from README.md)
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
-->

  <!-- The attribute attr-name-data-typeahead identifies an HTML input element for typeahead behaviour.
       You can override this parameter's value (in an importing stylesheet or via parameter passing, but make
       sure that CSS rules are adjusted accordingly.
       
       The value of the attribute is irrelevant (it can be empty), but you may want to use a value
       to distinguish multiple typeahead input elements.
       
       In the list that is generated when the popup becomes active, the code makes sure that the
       <ul> and <li> element also get this attribute, with the same value as the originating
       text input field.
  -->  
  <xsl:param name="attr-name-data-typeahead" select="'data-typeahead'"/>
  
  <!-- The attribute attr-name-data-typeahead-kb-active is only used internally. When arrow keys are
       used, this attribute identifies the currently active typeahead item in the list of items.
       You can override this parameter's value (in an importing stylesheet or via parameter passing,
       but you would only need to do so in the unlikely case that your existing application uses the
       same attribute for other purposes.
       The attribute does not have a value.
  -->
  <xsl:param name="attr-name-data-typeahead-kb-active" select="'data-typeahead-kb-active'"/>
  
  <!-- When the typeahead list pops up, it gets this z-index in order to position it above the normal content
       of the page. You can freely change its value in an importing stylesheet or via parameter passing.
       The value is applied to the style of the span element that should stand immediately to the right
       of the typeahead-input element.
  -->
  <xsl:param name="typeahead:z-index" select="'1000'"/>
  
  <!-- When the typeahead list pops up, this parameter defines the vertical space between the text box and the
       typeahead area below it (in px). You can freely change its value in an importing stylesheet or via parameter passing.
       The value is applied to the style of the span element that should stand immediately to the right
       of the typeahead-input element.
  -->
  <xsl:param name="typeahead:px-space-above-typeaheadlist" as="xs:double" select="2"/>
  
  <!-- The width of the typeahead area will be equal to the width of the text input. With this parameter, you can
       define this width to be the minimal width (value should be "minWidth") or the fixed with (value should be "width").
       You can freely change its value in an importing stylesheet or via parameter passing.
  -->
  <xsl:param name="typeahead:width-or-minwidth" as="xs:string" select="'width'"/>
  
  <!-- Constant that gives a name to the 'which' value of a keyboard event when the enter key is pressed (13)- -->
  <xsl:variable name="KEY-ENTER" as="xs:integer" select="13"/>
  <!-- Constant that gives a name to the 'which' value of a keyboard event when the escape key is pressed (27)- -->
  <xsl:variable name="KEY-ESCAPE" as="xs:integer" select="27"/>
  <!-- Constant that gives a name to the 'which' value of a keyboard event when the arrow-up is pressed (38)- -->
  <xsl:variable name="KEY-ARROW-UP" as="xs:integer" select="38"/>
  <!-- Constant that gives a name to the 'which' value of a keyboard event when the arrow-down is pressed (40)- -->
  <xsl:variable name="KEY-ARROW-DOWN" as="xs:integer" select="40"/>
  
  <!-- ********************** Functions that you must or may want to override ********************** -->
  
  <!-- This function is the only function that you *must* override, since its default implementation returns the
       empty sequence.
       This function retrieves the list of items that need to be shown in the popup. The items can be anything -
       a sequence of string, an XML document, JSON - just anything. Content can also come from an external document,
       using the doc() function, that in its turn may query a database. The sequence of items that it returns is transformed
       into an HTML ul/li structure by means of function typeahead:render-items, which essentially wraps each item into
       a li element by taking its string value (xsl:value-of) and wrapping those li elements into an ul.
       
       If you want to use the doc function, it may be convenient to load the document at startup (<xsl:initial-templage> or
       a template that you define your self with the invocation of SaxonJS). Store the value in a property of, e.g. <ixsl:page>,
       and retrieve it when needed.
       
       PARAMETERS
       - The textfield parameter corrresponds with the HTML input that triggered the popup.
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:function name="typeahead:calculate-items" as="item()*">
    <xsl:param name="textfield" as="element(input)"/>
    <xsl:param name="anything" as="item()*"/>
    
    <xsl:sequence select="()"/>
  </xsl:function>
  
  <!-- This function wraps the items returned by typeahead:calculate-items into li elements that are wrapped into an ul element.
       The items are converted to the content of the li element by means of typeahead:render-item, whose default is to simply
       take the string value (xsl:value-of), which will be adaquate in most cases.
       
       The ul and li elements all receive a data-typehead attribute, whose value is equal to the value of the data-typeahead
       attribute or the HTML input that triggered the popup. Note that data-typeahead can have another name by means of a parameter
       or redefinition.
       
       PARAMETERS
       - The items parameter corresponds to the sequence of items returned by typeahead:calculate-items..
       - The textfield parameter corrresponds with the HTML input that triggered the popup.
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:function name="typeahead:render-items" as="element(ul)?">
    <xsl:param name="items" as="item()*"/>
    <xsl:param name="textfield" as="element(input)"/>
    <xsl:param name="anything" as="item()*"/>
    
    <xsl:if  test="exists($items)">
      <xsl:variable name="typeahead-attr-value" as="xs:string" select="typeahead:get-typeahead-attribute-value($textfield)"/>      
      <ul>
        <xsl:attribute name="{$attr-name-data-typeahead}" select="$typeahead-attr-value"/>
        <xsl:for-each select="$items">
          <li>
            <xsl:attribute name="{$attr-name-data-typeahead}" select="$typeahead-attr-value"/>
            <xsl:copy-of select="typeahead:render-item(., $anything)"/>
          </li></xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:function>
  
  <!-- This function, called for each item by typeahead:render-items, converts each single item into a HTML structure that is  wrapped
       into a li element. Tdefault is to simply take the string value (xsl:value-of), which will be adaquate in most cases, but you may
       want to override this function by means of a function that generates more complex markup, such as inline markup. Note, however,
       that the function typeahead:get-value-from-li must be able to retrieve a string value that can eventually be stored into
       the HTML text input.

       PARAMETERS
       - The item parameter correspond to one of the items in the sequence returned by typeahead:calculate-items.
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything. Its value
         is passed down from typeahead:render-items.
  -->
  <xsl:function name="typeahead:render-item" as="item()*">
    <xsl:param name="item" as="item()"/>
    <xsl:param name="anything" as="item()*"/>
    
    <xsl:value-of select="$item"/>
  </xsl:function>
  
  <!-- This function retrieves the text from a popup li element that is to be stored in the corresponding HTML text input.
       Its default behaviour is to return the string value of the given li element, but if your li elements have a more complex
       structure (such as defined by typeahead:render-item), you need to override this function for the more specific behaviour.
       
       PARAMETERS
       - The li parameter is the element whose value is to be retrieved.
  -->
  <xsl:function name="typeahead:get-value-from-li" as="xs:string">
    <xsl:param name="li" as="element(li)"/>
    <xsl:param name="anything" as="item()*"/>
    
    <xsl:value-of select="$li"/>
  </xsl:function>
  
  <!-- ********************** Auxiliary functions ********************** -->
  
  <!-- This function always returns false(). It is used to fool the SaxonJS compiler, sothat it does not suppress
       the evaluation of expressions as could have happend if a predicate with just false() would have been used.
       The need to add a predicate like this arises in situations where you don't want the result of a function to end
       up in the output. For instance, for a call to a Javascript function, you are often interested in the side effect
       and not in the result.
  -->
  <xsl:function name="typeahead:false" as="xs:boolean" cache="yes">
    <xsl:sequence select="current-date() lt xs:date('2000-01-01')"/>
  </xsl:function>
  
  <!-- This function test if an element has a data-typeahead attribute, or the attribute that is defined by means of
       the attr-name-data-typeahead stylesheet parameters.

       PARAMETERS
       - The e parameter is the element that is tested for the presence of the attribute.
  -->
  <xsl:function name="typeahead:has-typeahead-attribute" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    
    <xsl:sequence select="exists($e/@*[name() eq $attr-name-data-typeahead])"></xsl:sequence>
  </xsl:function>
  
  <!-- This function return the value of the data-typeahead attribute, or the attribute that is defined by means of
       the attr-name-data-typeahead stylesheet parameters.

       PARAMETERS
       - The e parameter is the element whose attribute is evaluated. If there is no such attribute, an empty string
         is returned.
  -->
  <xsl:function name="typeahead:get-typeahead-attribute-value" as="xs:string">
    <xsl:param name="e" as="element()"/>
    
    <xsl:value-of select="$e/@*[name() eq $attr-name-data-typeahead]"/>
  </xsl:function>
  
  <!-- This function test if an element has a data-typeahead-kb-active attribute, or the attribute that is defined by means of
       the attr-name-data-typeahead stylesheet parameters. The data-typeahead-kb-active is added to a popup li element
       when it is activated by means of arrow keys on the keyboard.

       PARAMETERS
       - The e parameter is the element that is tested for the presence of the attribute.
  -->
  <xsl:function name="typeahead:has-typeahead-kb-active-attribute" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    
    <xsl:sequence select="exists($e/@*[name() eq $attr-name-data-typeahead-kb-active])"></xsl:sequence>
  </xsl:function>
  
  <!-- This function finds the HTML text input that corresponds with the given popup li element. The li element is supposed to
       be a descendant of a span element that is, with nothing in betweeen, right adjacent to the HTML input.
       
       PARAMETERS
       - The li parameter is the element whose corresponding HTML text input is to be found.
  -->
  <xsl:function name="typeahead:get-textbox-for-li" as="element(input)">
    <xsl:param name="li" as="element(li)"/>
    
    <xsl:variable name="span" as="element(span)" select="$li/ancestor::span[1]"/>
    <!-- A typehead input should immediately be followed by an empty span, nothing in between, not even spaces, comments or whatever. -->
    <xsl:sequence select="$span/preceding-sibling::node()[1][self::input]"/>
  </xsl:function>
  
  <!-- This function calls Javascript to retrieve the absolute top/left position of an element. The result is returned as a sequence
       of two numbers: 1. top 2. left.
       PARAMETERS
       - The e parameter is the element whose position is to be retrieved.
  -->
  <xsl:function name="typeahead:get-top-left" as="xs:double+">
    <xsl:param name="e" as="element()"/>
    
    <xsl:sequence select="typeahead:sum-parent-offsets($e, ixsl:get($e, 'offsetTop'), ixsl:get($e, 'offsetLeft'))"/>
  </xsl:function>
  
  <!-- This auxiliary function recursively sums all top and left offsets of position elements above (in stacking terms), starting at the element passed
       as parameter.
       The summing stops when the offsetParent of an element has an absolute or relative position (the offsets of that offsetParent are not taken into
       account).
       The purpose of this function is to find the absolute offsets of an element, relative to the first position element above it (in stacking order).
       The result is returned as a sequence of two numbers: 1. top 2. left.
  -->
  <xsl:function name="typeahead:sum-parent-offsets" as="xs:double+">
    <xsl:param name="elmt" as="element()"/>
    <xsl:param name="top" as="xs:double"/>
    <xsl:param name="left" as="xs:double"/>
    
    <xsl:variable name="offsetParent" as="element()?" select="ixsl:get($elmt, 'offsetParent')"/>
    <xsl:choose>
      <xsl:when test="$offsetParent and not(ixsl:style($offsetParent)?position = ('absolute', 'relative')) ">
        <xsl:sequence select="typeahead:sum-parent-offsets($offsetParent, $top + ixsl:get($offsetParent, 'offsetTop'), $left + ixsl:get($offsetParent, 'offsetLeft'))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="($top, $left)"></xsl:sequence>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- ********************** Templates for interactive behaviour ********************** -->
  
  <!-- This template is invoked when a click occurs in a typeahead li item.
       You may want to redefine or specialize it (maybe you will need a priority attribute) if you want
       to have distinct treatment of separate typeahead text inputs. Note that the value of the
       data-typeahead attribute of the text input is copied to the same attribute of the ul and the li
       items.
       
       Alternatively, you can choose not to override this template and instead redefine the templates or
       functions that it calls (maybe using an xsl:choose construct).
       
       Note that you don't *need* to redefine this template. It may well serve your purpose as it is.
  -->
  <xsl:template match="li[typeahead:has-typeahead-attribute(.)]" mode="ixsl:onclick">
    <xsl:call-template name="typeahead:apply-selection">
      <xsl:with-param name="textfield" select="typeahead:get-textbox-for-li(.)"/>
      <xsl:with-param name="span" select="ancestor::span[1]"/>
      <xsl:with-param name="value" select="typeahead:get-value-from-li(., ())"/>
      <xsl:with-param name="anything" select="()"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- This template is invoked when a keyup event occurs in a typeahead text input. Normal keys are
       dealt with by the text input (its value is updated), but arrow keys, the enter key and the
       escape key are dealt with in a special way, by calling appropriate other templates.
       
       You may want to redefine or specialize it (maybe you will need a priority attribute) if you want
       to have distinct treatment of separate typeahead text inputs. Note that the value of the
       data-typeahead attribute of the text input is copied to the same attribute of the ul and the li
       items.
       
       Alternatively, you can choose not to override this template and instead redefine the templates or
       functions that it calls (maybe using an xsl:choose construct).
       
       Note that you don't *need* to redefine this template. It may well serve your purpose as it is.
  -->
  <xsl:template match="input[typeahead:has-typeahead-attribute(.)]" mode="ixsl:onkeyup">
    <!-- In mode onkeyup, the key has been processed, so the value of the text box has been updated. -->
    <xsl:variable name="event" select="ixsl:event()"/>
    <xsl:variable name="whichKey" select="xs:integer(ixsl:get($event, 'which'))" as="xs:integer"/>
    <!-- A typehead input should immediately be followed by an empty span, nothing in between, not even spaces, comments or whatever. -->
    <xsl:variable name="corresponding-span" as="element(span)" select="following-sibling::node()[1][self::span]"/>

    <xsl:choose>
      <!-- Test if the key is an enter, escape, arrow up or arrow down key: -->
      <xsl:when test="$whichKey = ($KEY-ENTER, $KEY-ESCAPE, $KEY-ARROW-DOWN, $KEY-ARROW-UP)">
        <xsl:call-template name="typeahead:do-special-key">
          <xsl:with-param name="textfield" select="."/>
          <xsl:with-param name="span" select="$corresponding-span"/>
          <xsl:with-param name="whichKey" select="$whichKey"/>
          <xsl:with-param name="anything" select="()"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="typeahead:do-normal-key">
          <xsl:with-param name="textfield" select="."/>
          <xsl:with-param name="span" select="$corresponding-span"/>
          <xsl:with-param name="anything" select="()"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- ********************** Templates for interactive behaviour ********************** -->
  
  <!-- The xsl:initial template is required when SaxonJS does not need to do a transformation when loading the HTML page
       and the stylesheet. You can freely override it.
  -->
  <xsl:template name="xsl:initial-template">
    <!-- Nothing to do here (yet). -->
  </xsl:template>
  
  <!-- Deals with a keyup event in the typeahead textfield, by calling ivdnt:typeahead-insert-listitems. That
       template will store a sequence of, as described at ivdng:typeahead-insert-listitems.
       If the textfield becomes empty, the typehead list is hidden.
       
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:do-normal-key">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
    
    <xsl:variable name="absolute-top-left" as="xs:double+" select="typeahead:get-top-left($textfield)"/>
    
    <xsl:variable name="textfield-width" as="xs:double" select="ixsl:get($textfield, 'offsetWidth')"/>
    <xsl:variable name="textfield-height" as="xs:double" select="ixsl:get($textfield, 'offsetHeight')"/>
    <xsl:variable name="textfield-top" as="xs:double" select="$absolute-top-left[1]"/>
    <xsl:variable name="textfield-left" as="xs:double" select="$absolute-top-left[2]"/>
    
    <xsl:for-each select="$span">
      <!-- One iteration only -->
      <ixsl:set-style name="position" select="'absolute'"/>
      <ixsl:set-style name="z-index" select="$typeahead:z-index"/>
      <ixsl:set-style name="top" select="($textfield-top + $textfield-height) || 'px'"/>
      <ixsl:set-style name="left" select="$textfield-left || 'px'"/>
      <ixsl:set-style name="{$typeahead:width-or-minwidth}" select="$textfield-width || 'px'"/>
      <ixsl:set-style name="display" select="'inline-block'"/>

      <xsl:call-template name="typeahead:extra-activation-styles">
        <xsl:with-param name="textfield" select="$textfield"/>
        <xsl:with-param name="span" select="."/>
        <xsl:with-param name="anything" select="$anything"/>
      </xsl:call-template>
      
       <xsl:result-document href="?." method="ixsl:replace-content">
         <xsl:copy-of select="typeahead:calculate-items($textfield, $anything) => typeahead:render-items($textfield, $anything)"/>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  <!-- This template, which by default does nothing, can be overridden if you need a simple way to pass extra styles that should
       only be present when the typeahead is active and which cannot be statically defined in CSS (e.g., because of the position
       or dimensions of the textield).
       
       Note that you can also use this template to add some attribute to the span or the textfield; such an attribute can then
       be referenced in CSS.
       
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:extra-activation-styles">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
  </xsl:template>
  
  <!-- ********************** Auxiliary templates ********************** -->
  
  <!-- This template processes a special key, such as enter, arrows, escape .
    
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The whichKey parameter contains the key code as return for the 'which' property of the ixsl:event().
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:do-special-key">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="whichKey" as="xs:integer" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
    
    <xsl:choose>
      <xsl:when test="$whichKey eq $KEY-ENTER">
        <xsl:call-template name="typeahead:do-enter-key">
          <xsl:with-param name="textfield" select="$textfield"/>
          <xsl:with-param name="span" select="$span"/>
          <xsl:with-param name="anything" select="$anything"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$whichKey eq $KEY-ESCAPE">
        <xsl:call-template name="typeahead:do-escape-key">
          <xsl:with-param name="textfield" select="$textfield"/>
          <xsl:with-param name="span" select="$span"/>
          <xsl:with-param name="anything" select="$anything"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$whichKey eq $KEY-ARROW-DOWN">
        <xsl:call-template name="typeahead:do-arrow-key">
          <xsl:with-param name="textfield" select="$textfield"/>
          <xsl:with-param name="span" select="$span"/>
          <xsl:with-param name="direction" select="'down'"/>
          <xsl:with-param name="anything" select="$anything"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$whichKey eq $KEY-ARROW-UP">
        <xsl:call-template name="typeahead:do-arrow-key">
          <xsl:with-param name="textfield" select="$textfield"/>
          <xsl:with-param name="span" select="$span"/>
          <xsl:with-param name="direction" select="'up'"/>
          <xsl:with-param name="anything" select="$anything"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>    
  </xsl:template>
  
  <!-- This template processes an arrow key.
    
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The whichKey parameter contains the key code as return for the 'which' property of the ixsl:event().
       - The direction parameter is either 'up' or 'down' and indicates which popup li element neighbour should be selected.
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:do-arrow-key">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="direction" as="xs:string" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
    
    <xsl:variable name="ul" as="element(ul)?" select="$span/ul"/>
    <xsl:variable name="current-active-li" as="element(li)?" select="$ul/li[typeahead:has-typeahead-kb-active-attribute(.)]"/>
    <xsl:variable name="new-active-li" as="element(li)?"
      select="if ($current-active-li)
              then if ($direction eq 'up') then $current-active-li/preceding-sibling::li[1] else $current-active-li/following-sibling::li[1]
              else $ul/li[1]"/>
    <xsl:if test="$new-active-li">
      <xsl:if test="$current-active-li"><ixsl:remove-attribute name="{$attr-name-data-typeahead-kb-active}" object="$current-active-li"/></xsl:if>
      <ixsl:set-attribute name="{$attr-name-data-typeahead-kb-active}" select="''" object="$new-active-li"/>
      <xsl:call-template name="typeahead:scroll-into-view">
        <xsl:with-param name="e" select="$new-active-li"/>
      </xsl:call-template>
      
      <xsl:call-template name="typeahead:set-widget-value">
        <xsl:with-param name="textfield" select="$textfield"/>
        <xsl:with-param name="value" select="typeahead:get-value-from-li($new-active-li, $anything)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <!-- This template processes the enter key.
    
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:do-enter-key">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
    
    <xsl:variable name="ul" as="element(ul)?" select="$span/ul"/>
    <xsl:variable name="current-active-li" as="element(li)?" select="$ul/li[typeahead:has-typeahead-kb-active-attribute(.)]"/>
    <xsl:if test="$current-active-li">
      <xsl:call-template name="typeahead:apply-selection">
        <xsl:with-param name="textfield" select="$textfield"/>
        <xsl:with-param name="span" select="$span"/>
        <xsl:with-param name="value" select="typeahead:get-value-from-li($current-active-li, $anything)"/>
        <xsl:with-param name="anything" select="$anything"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <!-- This template processes the enter key.
    
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:do-escape-key">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
    
    <xsl:if test="exists($span/ul/li[typeahead:has-typeahead-kb-active-attribute(.)])">
      <!-- Only clear the textfield if some typing action with arrows has taken place (because the textfield has been changed due to the arrow effect.
           In fact, it might have been nicer if the original value were restored, but that would require us to maintain it somehow and that does not
           seem worth the trouble.
      -->
      <xsl:call-template name="typeahead:apply-selection">
        <xsl:with-param name="textfield" select="$textfield"/>
        <xsl:with-param name="span" select="$span"/>
        <xsl:with-param name="value" select="''"/>
        <xsl:with-param name="anything" select="$anything"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <!-- This template calls the Javascript function scrollIntoView in orde to make sure that the activated popup li item will be visible.
       PARAMETERS
       - The e parameter is the element that is to be scrolled into view.
  -->
  <xsl:template name="typeahead:scroll-into-view">
    <xsl:param name="e" as="element()" required="yes"/>
    
    <xsl:sequence select="ixsl:call($e, 'scrollIntoView', [])[typeahead:false()]"/>
  </xsl:template>
  
  <!-- This template is invoked when the users click a popup li element or presses enter or escape when
       a popup li element is activated by means of arrow keys. It fills the corresponding HTML text input
       with the required value and removes the popup list. It also removes all style settings of the popup
       span element (assigned to provide visual popup behaviour).
       
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
       - The value parameter contains the value to be stored into the textfield.
       - The anything parameter is not used in the default implementation, but it is there in case you want to pass
         some extra information in your redefition. It can be anything - a string, a sequence, a map - really anything.
  -->
  <xsl:template name="typeahead:apply-selection">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="span" as="element(span)" required="yes"/>
    <xsl:param name="value" as="xs:string" required="yes"/>
    <xsl:param name="anything" as="item()*" select="()" required="no"/>
    
    <xsl:call-template name="typeahead:set-widget-value">
      <xsl:with-param name="textfield" select="$textfield"/>
      <xsl:with-param name="value" select="$value"/>
    </xsl:call-template>
    
    <xsl:call-template name="typeahead:make-span-empty">
      <xsl:with-param name="span" select="$span"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- This template removes the popup list that is contained in the given span. It also removes all style settings of the popup
       span element (assigned to provide visual popup behaviour).
       PARAMETERS
       - The span parameter corresponds to the HTML span element that directly follows the HTML text input (nothing in between, not even
         whitespace, comment, or whatever).
  -->
  <xsl:template name="typeahead:make-span-empty">
    <xsl:param name="span" as="element(span)"/>
    
    <xsl:for-each select="$span">
      <!-- One time only -->
      <xsl:result-document href="?." method="ixsl:replace-content"/>
      
      <!-- Reset all applied style properties, sothat only class atrribute settings prevail. -->
      <ixsl:remove-attribute name="style"/>
    </xsl:for-each>
  </xsl:template>
  
  <!-- This template assigns a string value to an HTML text popup input.
       PARAMETERS
       - The textfield parameter corrresponds with the HTML textinput that triggered the popup.
       - The value parameter contains the value to be stored into the textfield.
  -->
  <xsl:template name="typeahead:set-widget-value">
    <xsl:param name="textfield" as="element(input)" required="yes"/>
    <xsl:param name="value" as="xs:string" required="yes"/>
    
    <ixsl:set-property name="value" select="$value" object="$textfield"/>
  </xsl:template>
  
</xsl:stylesheet>
