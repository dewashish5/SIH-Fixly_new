/**
 * Worker Reliability Badge & Profile Component SDK
 */
(function (window, document) {
  'use strict';

  class GigWorkerReliabilityWidget {
    constructor(config = {}) {
      this.containerId = config.containerId || 'worker-reliability-container';
      this.apiBaseUrl = config.apiBaseUrl || '';
      this.workerId = config.workerId || 'WRK-1001';
      this.init();
    }

    init() {
      this.container = document.getElementById(this.containerId);
      if (!this.container) {
        this.container = document.createElement('div');
        this.container.id = this.containerId;
        document.body.appendChild(this.container);
      }
      this.fetchAndRender();
    }

    async fetchAndRender() {
      try {
        const res = await fetch(this.apiBaseUrl + '/api/worker/' + this.workerId + '/score');
        const data = await res.json();
        this.render(data);
      } catch (err) {
        console.warn('API error, rendering fallback', err);
      }
    }

    render(data) {
      if (!data || !data.reliability_report) return;
      const r = data.reliability_report;
      const sub = r.sub_scores || {};
      const tierClass = r.tier || 'standard';
      let badgesHtml = '';
      if (r.badges && r.badges.length > 0) {
        badgesHtml = '<div class="wr-badges">' + r.badges.map(b => '<span class="wr-badge-chip">' + b + '</span>').join('') + '</div>';
      }
      const initialChar = (data.name || 'W').charAt(0);
      const categoriesText = (data.service_categories || []).map(c => c.replace('_', ' ').toUpperCase()).join(' • ');

      this.container.innerHTML = 
        <div class="wr-card">
          <div class="wr-header">
            <div class="wr-avatar"> + initialChar + </div>
            <div class="wr-info">
              <h3> + (data.name || 'Partner Profile') + </h3>
              <div class="categories">🛠️  + categoriesText + </div>
            </div>
            <span class="wr-tier-pill  + tierClass + "> + (r.tier_label || 'Standard') + </span>
          </div>

          <div class="wr-score-banner">
            <div class="wr-score-main">
              <div class="wr-score-number"> + r.overall_score + </div>
              <div class="wr-score-label">
                <strong>/ 100</strong><br/>
                Reliability Score
              </div>
            </div>
            <div style="text-align:right; font-size:11.5px; opacity:0.85;">
              <span>Evaluated:  + r.total_jobs_evaluated +  Jobs</span><br/>
              <span>Completed:  + r.completed_jobs_count +  Jobs</span>
            </div>
          </div>

          <div class="wr-breakdown">
            <div class="wr-factor-row">
              <div class="wr-factor-header">
                <span>⏱️ On-time Arrival Rate (25%):</span>
                <span class="val"> + sub.on_time_arrival_rate + %</span>
              </div>
              <div class="wr-progress-track">
                <div class="wr-progress-bar  + this.getColor(sub.on_time_arrival_rate) + " style="width:  + sub.on_time_arrival_rate + %"></div>
              </div>
            </div>

            <div class="wr-factor-row">
              <div class="wr-factor-header">
                <span>✅ Job Completion Rate (25%):</span>
                <span class="val"> + sub.job_completion_rate + %</span>
              </div>
              <div class="wr-progress-track">
                <div class="wr-progress-bar  + this.getColor(sub.job_completion_rate) + " style="width:  + sub.job_completion_rate + %"></div>
              </div>
            </div>

            <div class="wr-factor-row">
              <div class="wr-factor-header">
                <span>⭐ Customer Feedback Score (20%):</span>
                <span class="val"> + sub.customer_feedback_score + %</span>
              </div>
              <div class="wr-progress-track">
                <div class="wr-progress-bar  + this.getColor(sub.customer_feedback_score) + " style="width:  + sub.customer_feedback_score + %"></div>
              </div>
            </div>

            <div class="wr-factor-row">
              <div class="wr-factor-header">
                <span>🚫 Cancellation Resistance (15%):</span>
                <span class="val"> + sub.cancellation_resistance + %</span>
              </div>
              <div class="wr-progress-track">
                <div class="wr-progress-bar  + this.getColor(sub.cancellation_resistance) + " style="width:  + sub.cancellation_resistance + %"></div>
              </div>
            </div>

            <div class="wr-factor-row">
              <div class="wr-factor-header">
                <span>⚡ Lead Response Speed (15%):</span>
                <span class="val"> + sub.response_time_score + %</span>
              </div>
              <div class="wr-progress-track">
                <div class="wr-progress-bar  + this.getColor(sub.response_time_score) + " style="width:  + sub.response_time_score + %"></div>
              </div>
            </div>
          </div>

           + badgesHtml + 

          <div class="wr-summary-box">
            <strong>📋 AI Dependability Summary:</strong><br/>
            " + r.summary_text + "
          </div>
        </div>
      ;
    }

    getColor(val) {
      if (val >= 90) return 'green';
      if (val >= 80) return 'blue';
      if (val >= 70) return 'amber';
      return 'red';
    }
  }

  if (window.customElements && !window.customElements.get('gig-worker-reliability-badge')) {
    class GigWorkerReliabilityElement extends HTMLElement {
      connectedCallback() {
        new GigWorkerReliabilityWidget({
          containerId: this.id || 'gig-worker-rel-elem',
          workerId: this.getAttribute('worker-id') || 'WRK-1001',
          apiBaseUrl: this.getAttribute('api-url') || ''
        });
      }
    }
    window.customElements.define('gig-worker-reliability-badge', GigWorkerReliabilityElement);
  }

  window.GigWorkerReliability = {
    init: function (config) {
      return new GigWorkerReliabilityWidget(config);
    }
  };
})(window, document);
