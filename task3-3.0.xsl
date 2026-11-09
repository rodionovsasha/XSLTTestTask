<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" expand-text="yes">
    <xsl:mode on-no-match="shallow-copy"/>
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:param name="debug" as="xs:boolean" select="true()"/>

    <xsl:key name="feature-by-id" match="*:feature" use="@id"/>
    <xsl:key name="anchor-by-feature-id" match="*:featureAnchor" use="@features"/>
    <!-- Index feature math directly instead of repeatedly walking feature subtrees. -->
    <xsl:key name="math-by-feature-id" match="*:math" use="ancestor::*:feature/@id"/>

    <xsl:variable name="source-document" as="document-node()" select="/"/>

    <!-- A feature is counted where its featureAnchor occurs, not in featureGroup. -->
    <xsl:template match="/">
        <xsl:if test="$debug">
            <xsl:message>[DEBUG] Transformation started; math count={count(//*:math)}</xsl:message>
        </xsl:if>
        <xsl:call-template name="validate-input"/>
        <xsl:apply-templates/>
        <xsl:if test="$debug">
            <xsl:message>[DEBUG] Transformation completed.</xsl:message>
        </xsl:if>
    </xsl:template>

    <xsl:template name="validate-input">
        <xsl:for-each select="//*:featureAnchor">
            <xsl:if test="not(@features)
                          or @features ne normalize-space(@features)
                          or contains(normalize-space(@features), ' ')">
                <xsl:message terminate="yes">Each featureAnchor/@features must contain exactly one feature ID.</xsl:message>
            </xsl:if>
            <xsl:if test="count(key('feature-by-id', @features, $source-document)) ne 1">
                <xsl:message terminate="yes">Every featureAnchor must reference exactly one feature.</xsl:message>
            </xsl:if>
        </xsl:for-each>

        <xsl:for-each select="//*:feature">
            <xsl:if test="not(@id) or count(key('anchor-by-feature-id', @id, $source-document)) ne 1">
                <xsl:message terminate="yes">Every feature must have an ID and exactly one featureAnchor.</xsl:message>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:math">
        <xsl:variable name="feature" as="element()?" select="ancestor::*:feature[1]"/>
        <xsl:variable name="number" as="xs:integer"
            select="if ($feature)
                    then let $anchor := key('anchor-by-feature-id', $feature/@id, $source-document)
                         return count($anchor/preceding::*:math[not(ancestor::*:feature)])
                              + count(key('math-by-feature-id', $anchor/preceding::*:featureAnchor/@features, $source-document))
                              + count(preceding::*:math[ancestor::*:feature[@id = $feature/@id]])
                              + 1
                    else count(preceding::*:math[not(ancestor::*:feature)])
                         + count(key('math-by-feature-id', preceding::*:featureAnchor/@features, $source-document))
                         + 1"/>
        <xsl:if test="$debug">
            <xsl:message>[DEBUG] math id="{@id}" feature="{$feature/@id}" number={$number}</xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:attribute name="number" select="$number"/>
            <xsl:copy-of select="@* except @number"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
