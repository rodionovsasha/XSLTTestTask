<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:key name="feature-by-id" match="*[local-name() = 'feature']" use="@id"/>
    <xsl:key name="anchor-by-feature-id" match="*[local-name() = 'featureAnchor']" use="@features"/>

    <!--
        The logical document order expands a feature at its featureAnchor.  The
        featureGroup remains in the result, but its math nodes are not counted
        in their physical location.
    -->
    <xsl:template match="/">
        <xsl:call-template name="validate-input"/>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template name="validate-input">
        <xsl:for-each select="//*[local-name() = 'featureAnchor']">
            <xsl:if test="not(@features)
                          or @features != normalize-space(@features)
                          or contains(normalize-space(@features), ' ')">
                <xsl:message terminate="yes">Each featureAnchor/@features must contain exactly one feature ID.</xsl:message>
            </xsl:if>
            <xsl:if test="count(key('feature-by-id', @features)) != 1">
                <xsl:message terminate="yes">Every featureAnchor must reference exactly one feature.</xsl:message>
            </xsl:if>
        </xsl:for-each>

        <xsl:for-each select="//*[local-name() = 'feature']">
            <xsl:if test="not(@id) or count(key('anchor-by-feature-id', @id)) != 1">
                <xsl:message terminate="yes">Every feature must have an ID and exactly one featureAnchor.</xsl:message>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[local-name() = 'math']">
        <xsl:variable name="feature" select="ancestor::*[local-name() = 'feature'][1]"/>
        <xsl:copy>
            <xsl:attribute name="number">
                <xsl:choose>
                    <xsl:when test="$feature">
                        <xsl:variable name="anchor"
                            select="key('anchor-by-feature-id', $feature/@id)"/>
                        <xsl:value-of select="
                            count($anchor/preceding::*[local-name() = 'math' and not(ancestor::*[local-name() = 'feature'])])
                            + count(key('feature-by-id', $anchor/preceding::*[local-name() = 'featureAnchor']/@features)//*[local-name() = 'math'])
                            + count(preceding::*[local-name() = 'math' and ancestor::*[local-name() = 'feature' and @id = $feature/@id]])
                            + 1"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="
                            count(preceding::*[local-name() = 'math' and not(ancestor::*[local-name() = 'feature'])])
                            + count(key('feature-by-id', preceding::*[local-name() = 'featureAnchor']/@features)//*[local-name() = 'math'])
                            + 1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:copy-of select="@*[not(namespace-uri() = '' and local-name() = 'number')]"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
