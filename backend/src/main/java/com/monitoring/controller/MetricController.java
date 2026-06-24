package com.monitoring.controller;

import com.monitoring.model.Metric;
import com.monitoring.service.MetricService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/metrics")
public class MetricController {

    private final MetricService service;

    public MetricController(MetricService service) {
        this.service = service;
    }

    @GetMapping
    public List<Metric> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Metric> getById(@PathVariable Long id) {
        return service.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Metric create(@RequestBody Metric metric) {
        return service.save(metric);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Metric> update(@PathVariable Long id, @RequestBody Metric metric) {
        return service.findById(id).map(existing -> {
            metric.setId(id);
            return ResponseEntity.ok(service.save(metric));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        return service.findById(id).map(m -> {
            service.delete(id);
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }
}
