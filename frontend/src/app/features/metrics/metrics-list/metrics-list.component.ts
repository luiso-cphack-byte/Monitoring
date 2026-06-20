import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { Metric, MetricService } from '../../../core/services/metric.service';

@Component({
  selector: 'app-metrics-list',
  standalone: true,
  imports: [CommonModule, RouterModule, MatTableModule, MatButtonModule, MatIconModule, MatProgressSpinnerModule],
  templateUrl: './metrics-list.component.html',
  styleUrl: './metrics-list.component.scss'
})
export class MetricsListComponent implements OnInit {
  metrics: Metric[] = [];
  displayedColumns = ['name', 'value', 'unit', 'source', 'timestamp', 'actions'];
  loading = true;

  constructor(private metricService: MetricService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.metricService.getAll().subscribe({
      next: data => { this.metrics = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  delete(id: number): void {
    this.metricService.delete(id).subscribe(() => this.load());
  }
}
