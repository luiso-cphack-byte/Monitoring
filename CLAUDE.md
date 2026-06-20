# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build and package as WAR
mvn package

# Build without running tests
mvn package -DskipTests

# Run tests
mvn test

# Run a single test class
mvn test -Dtest=MyTestClass

# Clean build artifacts
mvn clean

# Clean and rebuild
mvn clean package
```

To deploy and run locally, deploy `target/Monitoring.war` to a servlet container (e.g., Tomcat, Jetty).

## Architecture

This is a Maven WAR project (`org.example:Monitoring:1.0-SNAPSHOT`) — a Java web application packaged as a WAR for deployment to a servlet container.

- `src/main/webapp/` — web content root (JSP pages, static assets)
- `src/main/webapp/WEB-INF/web.xml` — servlet deployment descriptor (currently Servlet 2.3)
- `src/main/java/` — Java source (servlets, services — not yet created)
- `src/test/java/` — test source

The project is configured in IntelliJ IDEA and uses JUnit 3.8.1 for tests (declared in `pom.xml`). The web.xml and pom.xml are both at their initial scaffold state with no custom servlets or dependencies added yet.
