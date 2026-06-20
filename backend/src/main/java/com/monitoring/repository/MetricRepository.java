package com.monitoring.repository;

import com.monitoring.model.Metric;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MetricRepository extends JpaRepository<Metric, Long> {
    List<Metric> findBySource(String source);
    List<Metric> findByName(String name);
}
