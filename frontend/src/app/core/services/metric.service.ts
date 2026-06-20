import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Metric {
  id?: number;
  name: string;
  value: number;
  unit: string;
  source: string;
  timestamp?: string;
}

@Injectable({
  providedIn: 'root'
})
export class MetricService {
  private readonly url = `${environment.apiUrl}/api/metrics`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<Metric[]> {
    return this.http.get<Metric[]>(this.url);
  }

  getById(id: number): Observable<Metric> {
    return this.http.get<Metric>(`${this.url}/${id}`);
  }

  create(metric: Metric): Observable<Metric> {
    return this.http.post<Metric>(this.url, metric);
  }

  update(id: number, metric: Metric): Observable<Metric> {
    return this.http.put<Metric>(`${this.url}/${id}`, metric);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
