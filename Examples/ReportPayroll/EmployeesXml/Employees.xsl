<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">

  <xsl:template match="/EmployeesXml">
    <Employees>
      <xsl:for-each select="Employees">
        <Employee>
          <Id>
            <xsl:value-of select="Id" />
          </Id>
          <Status>
            <xsl:value-of select="Status" />
          </Status>
          <Created>
            <xsl:value-of select="Created" />
          </Created>
          <Updated>
            <xsl:value-of select="Updated" />
          </Updated>
          <TenantId>
            <xsl:value-of select="TenantId" />
          </TenantId>
          <Identifier>
            <xsl:value-of select="Identifier" />
          </Identifier>
          <FirstName>
            <xsl:value-of select="FirstName" />
          </FirstName>
          <LastName>
            <xsl:value-of select="LastName" />
          </LastName>
          <Language>
            <xsl:value-of select="Language" />
          </Language>
          <Divisions>
            <xsl:value-of select="Divisions" />
          </Divisions>
        </Employee>
      </xsl:for-each>
    </Employees>
  </xsl:template>

</xsl:stylesheet>
