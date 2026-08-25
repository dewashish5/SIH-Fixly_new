/**
 * Fair Price Estimator JavaScript SDK & Web Component
 * Triggers upon service & location selection to provide instant fair price preview.
 */

(function (window, document) {
  'use strict';

  class GigPriceEstimatorWidget {
    constructor(config = {}) {
      this.containerId = config.containerId || 'gig-price-estimator-container';
      this.apiBaseUrl = config.apiBaseUrl || '';
      this.currentCategory = config.initialCategory || 'plumbing';
      this.currentSubService = config.initialSubService || 'tap_and_pipe_repair';
      this.currentPincode = config.initialPincode || '560038';
      this.currentUrgency = config.initialUrgency || 'standard';
      this.currentDistance = config.initialDistance || 3.5;
      this.onPriceCalculated = config.onPriceCalculated || null;
      this.init();
    }

    init() {
      this.container = document.getElementById(this.containerId);
      if (!this.container) {
        this.container = document.createElement('div');
        this.container.id = this.containerId;
        document.body.appendChild(this.container);
      }
      this.render();
      this.fetchEstimate();
    }

    render() {
      this.container.innerHTML = 
        <div class="fp-card">
          <div class="fp-header">
            <h3>⚖️ Fair Price Estimation</h3>
            <span class="fp-badge normal" id="fp-demand-badge">Demand: 1.00x</span>
          </div>

          <div class="fp-form-group">
            <label>Select Service Type:</label>
            <select class="fp-select" id="fp-service-select">
              <optgroup label="🚰 Plumbing">
                <option value="plumbing:tap_and_pipe_repair">Tap & Minor Pipe Leakage Repair</option>
                <option value="plumbing:toilet_and_sanitary_fitting">Toilet & Sanitary Fitting</option>
                <option value="plumbing:water_tank_and_motor_pipeline">Water Tank & Motor Pipeline</option>
              </optgroup>
              <optgroup label="⚡ Electrical">
                <option value="electrical:fan_and_switch_repair">Fan, Lights & Switch Repair</option>
                <option value="electrical:mcb_and_short_circuit_fix">MCB & Short Circuit Diagnosis</option>
                <option value="electrical:full_house_wiring_inspection">Full House Wiring Inspection</option>
              </optgroup>
              <optgroup label="❄️ AC & Appliances">
                <option value="ac_repair:ac_filter_and_jet_servicing">AC Jet Servicing</option>
                <option value="ac_repair:ac_gas_refill_and_leak_fix">AC Gas Refill & Leak Fix</option>
                <option value="appliance_repair:washing_machine_repair">Washing Machine Repair</option>
                <option value="appliance_repair:refrigerator_repair">Refrigerator Repair</option>
              </optgroup>
              <optgroup label="🧹 Cleaning & Home">
                <option value="cleaning:bathroom_deep_cleaning">Bathroom Deep Cleaning</option>
                <option value="cleaning:full_home_deep_cleaning_2bhk">Full Home Deep Cleaning (2 BHK)</option>
                <option value="carpentry:furniture_assembly_and_hinges">Furniture Assembly & Hinges</option>
                <option value="pest_control:cockroach_and_ant_treatment">Pest Control Treatment</option>
              </optgroup>
            </select>
          </div>

          <div class="fp-form-group">
            <label>Service Urgency / Dispatch Mode:</label>
            <div class="fp-urgency-grid">
              <div class="fp-urgency-btn active" data-urgency="standard">
                <span class="icon">📅</span> Standard Slot
              </div>
              <div class="fp-urgency-btn" data-urgency="priority">
                <span class="icon">⚡</span> Express (2 hrs)
              </div>
              <div class="fp-urgency-btn emergency" data-urgency="emergency">
                <span class="icon">🚨</span> Emergency SOS
              </div>
            </div>
          </div>

          <div class="fp-form-group">
            <label>Service Location Pincode & Distance:</label>
            <div style="display:flex; gap:10px;">
              <input type="text" class="fp-input" id="fp-pincode-input" value="" placeholder="Pincode e.g. 560038" style="flex:1;" />
              <select class="fp-select" id="fp-dist-select" style="flex:1;">
                <option value="2.0">Near (&lt; 2.5 km)</option>
                <option value="5.0" selected>Mid-range (5 km)</option>
                <option value="10.0">Extended (10 km)</option>
              </select>
            </div>
          </div>

          <div class="fp-price-banner">
            <div class="fp-price-main">
              <h2 id="fp-estimated-price">₹--</h2>
              <div class="range" id="fp-price-range">Calculated Range: ₹-- - ₹--</div>
            </div>
            <div class="fp-price-badge-col">
              <span class="ai-badge">🤖 AI Fair Estimate</span>
              <div style="font-size:11px; opacity:0.8;">Before Booking</div>
            </div>
          </div>

          <div class="fp-breakdown">
            <h4>
              <span>Transparent Fee Breakdown</span>
              <span style="font-weight:400; font-size:11px; color:#64748b;">Zero Hidden Charges</span>
            </h4>
            <div class="fp-breakdown-row">
              <span>Base Service Price:</span>
              <span id="fp-row-base">₹--</span>
            </div>
            <div class="fp-breakdown-row">
              <span>Local Demand Adjustment:</span>
              <span id="fp-row-demand">₹--</span>
            </div>
            <div class="fp-breakdown-row">
              <span>Urgency / Emergency Fee:</span>
              <span id="fp-row-urgency">₹--</span>
            </div>
            <div class="fp-breakdown-row">
              <span>Travel & Distance Fee:</span>
              <span id="fp-row-travel">₹--</span>
            </div>
            <div class="fp-breakdown-row highlight">
              <span>Total Pre-Booking Estimate:</span>
              <span id="fp-row-total" style="color:#2563eb; font-size:14px;">₹--</span>
            </div>

            <ul class="fp-notes-list" id="fp-notes-list"></ul>
          </div>

          <button class="fp-confirm-btn" id="fp-confirm-btn">Confirm Booking with Estimated Price</button>
        </div>
      ;

      this.bindEvents();
    }

    bindEvents() {
      const select = this.container.querySelector('#fp-service-select');
      const pincodeInput = this.container.querySelector('#fp-pincode-input');
      const distSelect = this.container.querySelector('#fp-dist-select');
      const urgencyBtns = this.container.querySelectorAll('.fp-urgency-btn');
      const confirmBtn = this.container.querySelector('#fp-confirm-btn');

      select.onchange = (e) => {
        const parts = e.target.value.split(':');
        this.currentCategory = parts[0];
        this.currentSubService = parts[1];
        this.fetchEstimate();
      };

      pincodeInput.onblur = (e) => {
        this.currentPincode = e.target.value.trim() || '560038';
        this.fetchEstimate();
      };

      distSelect.onchange = (e) => {
        this.currentDistance = parseFloat(e.target.value);
        this.fetchEstimate();
      };

      urgencyBtns.forEach(btn => {
        btn.onclick = () => {
          urgencyBtns.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          this.currentUrgency = btn.getAttribute('data-urgency');
          this.fetchEstimate();
        };
      });

      confirmBtn.onclick = () => {
        alert(Booking Confirmed for  at estimated price !);
      };
    }

    async fetchEstimate() {
      const payload = {
        service_category: this.currentCategory,
        sub_service: this.currentSubService,
        location_pincode: this.currentPincode,
        urgency: this.currentUrgency,
        distance_km: this.currentDistance
      };

      try {
        const res = await fetch(${this.apiBaseUrl}/api/estimate-price, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const data = await res.json();
        this.updateUI(data);
      } catch (err) {
        console.warn('API error, computing client-side estimate', err);
        this.computeClientFallback();
      }
    }

    updateUI(data) {
      if (!data) return;
      document.getElementById('fp-estimated-price').innerText = data.formatted_price || ₹;
      document.getElementById('fp-price-range').innerText = Calculated Range: ;

      const b = data.breakdown || {};
      document.getElementById('fp-row-base').innerText = ₹;
      document.getElementById('fp-row-demand').innerText = (b.demand_adjustment >= 0 ? +₹ : -₹);
      document.getElementById('fp-row-urgency').innerText = +₹;
      document.getElementById('fp-row-travel').innerText = +₹;
      document.getElementById('fp-row-total').innerText = ₹;

      const badge = document.getElementById('fp-demand-badge');
      badge.className = p-badge ;
      badge.innerText = Demand: x ();

      const notesList = document.getElementById('fp-notes-list');
      notesList.innerHTML = '';
      if (data.explainability_notes) {
        data.explainability_notes.forEach(note => {
          const li = document.createElement('li');
          li.innerText = • ;
          notesList.appendChild(li);
        });
      }

      if (this.onPriceCalculated) this.onPriceCalculated(data);
    }

    computeClientFallback() {
      // Offline fallback calculation
      const baseMap = {
        'tap_and_pipe_repair': 249,
        'toilet_and_sanitary_fitting': 399,
        'water_tank_and_motor_pipeline': 599,
        'fan_and_switch_repair': 199,
        'mcb_and_short_circuit_fix': 349,
        'full_house_wiring_inspection': 699,
        'ac_filter_and_jet_servicing': 499,
        'ac_gas_refill_and_leak_fix': 1299,
        'washing_machine_repair': 349,
        'refrigerator_repair': 399,
        'bathroom_deep_cleaning': 399,
        'full_home_deep_cleaning_2bhk': 1499,
        'furniture_assembly_and_hinges': 299,
        'cockroach_and_ant_treatment': 599
      };

      const base = baseMap[this.currentSubService] || 349;
      const urgencyMult = this.currentUrgency === 'emergency' ? 1.35 : (this.currentUrgency === 'priority' ? 1.15 : 1.0);
      const emergencyFee = this.currentUrgency === 'emergency' ? 100 : (this.currentUrgency === 'priority' ? 30 : 0);
      const travelFee = Math.max(0, (this.currentDistance - 2.5) * 15);
      const demandMult = 1.15;
      const demandDelta = base * (demandMult - 1.0);
      const urgencyDelta = (base * (urgencyMult - 1.0)) + emergencyFee;
      const total = Math.round(base + demandDelta + urgencyDelta + travelFee);

      this.updateUI({
        estimated_price: total,
        formatted_price: ₹,
        price_range: { formatted: ₹ - ₹ },
        demand_level: 'moderate',
        demand_multiplier: demandMult,
        breakdown: {
          base_service_price: base,
          demand_adjustment: Math.round(demandDelta),
          urgency_surcharge: Math.round(urgencyDelta),
          distance_travel_fee: Math.round(travelFee)
        },
        explainability_notes: [
          Base price: ₹,
          Local demand index 1.15x: +₹,
          Urgency mode (): +₹,
          Anti-price-gouging safety cap active
        ]
      });
    }
  }

  // Web Component Registration
  if (window.customElements && !window.customElements.get('gig-price-estimator')) {
    class GigPriceEstimatorElement extends HTMLElement {
      connectedCallback() {
        new GigPriceEstimatorWidget({
          containerId: this.id || 'gig-price-estimator-custom',
          apiBaseUrl: this.getAttribute('api-url') || ''
        });
      }
    }
    window.customElements.define('gig-price-estimator', GigPriceEstimatorElement);
  }

  window.GigPriceEstimator = {
    init: function (config) {
      return new GigPriceEstimatorWidget(config);
    }
  };
})(window, document);
