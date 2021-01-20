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

</xsl:stylesheet>
