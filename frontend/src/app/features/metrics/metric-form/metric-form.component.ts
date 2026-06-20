import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { Metric, MetricService } from '../../../core/services/metric.service';

@Component({
  selector: 'app-metric-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  templateUrl: './metric-form.component.html',
  styleUrl: './metric-form.component.scss'
})
export class MetricFormComponent implements OnInit {
  form: FormGroup;
  editId?: number;

  constructor(
    private fb: FormBuilder,
    private service: MetricService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.form = this.fb.group({
      name: ['', Validators.required],
      value: [null, Validators.required],
      unit: [''],
      source: ['']
    });
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.editId = +id;
      this.service.getById(this.editId).subscribe(m => this.form.patchValue(m));
    }
  }

  submit(): void {
    if (this.form.invalid) return;
    const metric: Metric = this.form.value;
    const op = this.editId
      ? this.service.update(this.editId, metric)
      : this.service.create(metric);
    op.subscribe(() => this.router.navigate(['/metrics']));
  }
}
