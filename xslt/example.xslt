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
  
  <xsl:import href="typeahead.xslt"/>
  
  <xsl:variable name="trees" as="xs:string+" select="('oak', 'baobap', 'birch', 'elm', 'pine', 'palm', 'sequoia', 'willow')"/>
  <xsl:variable name="animals" as="xs:string+" select="('mouse', 'tiger', 'lion', 'elephant', 'velociraptor', 'peacock', 'trout', 'carp', 'sparrow', 'robin', 'homo sapiens', 'homo insipiens')"/>
  
  <xsl:function name="typeahead:calculate-items" as="item()*">
    <xsl:param name="textfield" as="element(input)"/>
    <xsl:param name="anything" as="item()*"/>
    
    <xsl:variable name="list" as="xs:string+">
      <xsl:choose>
        <xsl:when test="$textfield/@data-typeahead eq 'trees'">
          <xsl:sequence select="$trees"/>
        </xsl:when>
        <xsl:when test="$textfield/@data-typeahead eq 'animals'">
          <xsl:sequence select="$animals"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="text-value" select="ixsl:get($textfield, 'value')"/>
    
    <xsl:sequence select="if ($text-value ne '') then $list[starts-with(., $text-value)] else ()"/>
  </xsl:function>
  
</xsl:stylesheet>
