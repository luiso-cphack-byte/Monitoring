package com.monitoring.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.security.web.header.writers.XXssProtectionHeaderWriter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .headers(headers -> {
                headers.contentSecurityPolicy(csp ->
                    csp.policyDirectives("default-src 'none'; frame-ancestors 'none'")
                );
                headers.referrerPolicy(rp ->
                    rp.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER)
                );
                headers.permissionsPolicy(pp ->
                    pp.policy("camera=(), microphone=(), geolocation=()")
                );
                headers.httpStrictTransportSecurity(hsts ->
                    hsts.includeSubDomains(true).maxAgeInSeconds(31536000)
                );
                headers.xssProtection(xss ->
                    xss.headerValue(XXssProtectionHeaderWriter.HeaderValue.DISABLED)
                );
                headers.frameOptions(fo -> fo.deny());
                headers.contentTypeOptions(Customizer.withDefaults());
            });
        return http.build();
    }
}
