<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:param name="debug" select="'true'"/>

    <xsl:key name="feature-by-id" match="*[local-name() = 'feature']" use="@id"/>
    <xsl:key name="anchor-by-feature-id" match="*[local-name() = 'featureAnchor']" use="@features"/>

    <xsl:variable name="source-document" as="document-node()" select="/"/>

    <!-- A feature is counted where its featureAnchor occurs, not in featureGroup. -->
    <xsl:template match="/">
        <xsl:if test="$debug = 'true'">
            <xsl:message>[DEBUG] Transformation started; math count=<xsl:value-of select="count(//*[local-name() = 'math'])"/></xsl:message>
        </xsl:if>
        <xsl:call-template name="validate-input"/>
        <xsl:apply-templates/>
        <xsl:if test="$debug = 'true'">
            <xsl:message>[DEBUG] Transformation completed.</xsl:message>
        </xsl:if>
    </xsl:template>

    <xsl:template name="validate-input">
        <xsl:for-each select="//*[local-name() = 'featureAnchor']">
            <xsl:if test="not(@features)
                          or @features ne normalize-space(@features)
                          or contains(normalize-space(@features), ' ')">
                <xsl:message terminate="yes">Each featureAnchor/@features must contain exactly one feature ID.</xsl:message>
            </xsl:if>
            <xsl:if test="count(key('feature-by-id', @features, $source-document)) ne 1">
                <xsl:message terminate="yes">Every featureAnchor must reference exactly one feature.</xsl:message>
            </xsl:if>
        </xsl:for-each>

        <xsl:for-each select="//*[local-name() = 'feature']">
            <xsl:if test="not(@id) or count(key('anchor-by-feature-id', @id, $source-document)) ne 1">
                <xsl:message terminate="yes">Every feature must have an ID and exactly one featureAnchor.</xsl:message>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*[local-name() = 'math']">
        <xsl:variable name="feature" select="ancestor::*[local-name() = 'feature'][1]"/>
        <xsl:variable name="anchor"
            select="key('anchor-by-feature-id', $feature/@id, $source-document)"/>
        <xsl:variable name="number" as="xs:integer"
            select="if ($feature)
                    then count($anchor/preceding::*[local-name() = 'math' and not(ancestor::*[local-name() = 'feature'])])
                         + count(key('feature-by-id', $anchor/preceding::*[local-name() = 'featureAnchor']/@features, $source-document)//*[local-name() = 'math'])
                         + count(preceding::*[local-name() = 'math' and ancestor::*[local-name() = 'feature' and @id = $feature/@id]])
                         + 1
                    else count(preceding::*[local-name() = 'math' and not(ancestor::*[local-name() = 'feature'])])
                         + count(key('feature-by-id', preceding::*[local-name() = 'featureAnchor']/@features, $source-document)//*[local-name() = 'math'])
                         + 1"/>
        <xsl:if test="$debug = 'true'">
            <xsl:message>[DEBUG] math id="<xsl:value-of select="@id"/>" feature="<xsl:value-of select="$feature/@id"/>" number=<xsl:value-of select="$number"/></xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:attribute name="number" select="$number"/>
            <xsl:copy-of select="@* except @number"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:mode on-no-match="shallow-copy"/>
</xsl:stylesheet>
