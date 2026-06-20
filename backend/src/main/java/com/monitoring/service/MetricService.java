package com.monitoring.service;

import com.monitoring.model.Metric;
import com.monitoring.repository.MetricRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class MetricService {

    private final MetricRepository repository;

    @Cacheable("metrics")
    public List<Metric> findAll() {
        return repository.findAll();
    }

    public Optional<Metric> findById(Long id) {
        return repository.findById(id);
    }

    @CacheEvict(value = "metrics", allEntries = true)
    public Metric save(Metric metric) {
        return repository.save(metric);
    }

    @CacheEvict(value = "metrics", allEntries = true)
    public void delete(Long id) {
        repository.deleteById(id);
    }
}
