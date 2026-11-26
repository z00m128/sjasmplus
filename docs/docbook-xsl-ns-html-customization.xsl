<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- make the output UTF-8 encoded, the default template insists on "ISO-8859-1", but does
not produce fully valid HTML document, so it fails in modern browsers (which fall back to
UTF-8 in such case) -->
<xsl:output method="html"
            encoding="UTF-8"
            indent="no"/>

<!-- add 'lang="en"' to <html> -->
<xsl:template name="root.attributes">
  <xsl:attribute name="lang">en</xsl:attribute>
</xsl:template>

<!-- add <!DOCTYPE html> to the beginning of the html file -->
<xsl:template name="user.preroot">
  <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
</xsl:template>

<!-- make IndexTerm items to point directly onto their "anchor" from Index page -->
<xsl:param name="index.links.to.section" select="0"></xsl:param>

<!-- variable list term separator -->
<xsl:param name="variablelist.term.separator" select="''"/>

<!-- variable list term break after -->
<xsl:param name="variablelist.term.break.after" select="1"/>

<!-- template to create an anchor - patched to remove auto-generated id anchors for examples, etc... -->
<xsl:template name="anchor">
  <xsl:param name="node" select="."/>
  <xsl:param name="conditional" select="1"/>
  <xsl:if test="$generate.id.attributes = 0 and ($node/@id or $node/@xml:id)">
    <a>
      <xsl:attribute name="name">
        <xsl:call-template name="object.id">
          <xsl:with-param name="object" select="$node"/>
        </xsl:call-template>
      </xsl:attribute>
    </a>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
