import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'metrics', pathMatch: 'full' },
  {
    path: 'metrics',
    loadComponent: () =>
      import('./features/metrics/metrics-list/metrics-list.component').then(m => m.MetricsListComponent)
  },
  {
    path: 'metrics/new',
    loadComponent: () =>
      import('./features/metrics/metric-form/metric-form.component').then(m => m.MetricFormComponent)
  },
  {
    path: 'metrics/:id/edit',
    loadComponent: () =>
      import('./features/metrics/metric-form/metric-form.component').then(m => m.MetricFormComponent)
  }
];
