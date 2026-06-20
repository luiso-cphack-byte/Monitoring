# Monitoring

Aplicación web Java construida con Maven, empaquetada como WAR para despliegue en un servidor de aplicaciones (Tomcat, Jetty, etc.).

## Requisitos

- Java JDK 8+
- Maven 3.x
- Servidor de aplicaciones compatible con Servlet (Tomcat, Jetty)

## Construcción

```bash
# Compilar y generar el WAR
mvn package

# Limpiar y reconstruir
mvn clean package

# Saltar tests
mvn package -DskipTests
```

El archivo WAR se genera en `target/Monitoring.war`.

## Tests

```bash
# Ejecutar todos los tests
mvn test

# Ejecutar una clase de test específica
mvn test -Dtest=NombreDelTest
```

## Despliegue

Copia `target/Monitoring.war` al directorio `webapps/` de tu servidor Tomcat, o configura el servidor desde tu IDE.
