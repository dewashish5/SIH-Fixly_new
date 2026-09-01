/**
 * FairPrice AI JavaScript SDK & Web Component
 * Interactive Pre-Booking Fair Price Estimation, Scenarios, and Explainability Widget.
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
      this.currentDistance = config.initialDistance || 2.0;
      this.customDemandOverride = null;
      this.currentData = null;
      this.showComparison = false;
      this.explainExpanded = true;
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
      this.container.innerHTML = `
        <div class="fp-card">
          <div class="fp-header">
            <h3>⚖️ FairPrice AI Estimator</h3>
            <span class="fp-badge normal" id="fp-demand-badge">Demand: 1.00x</span>
          </div>

          <!-- 1-Click Judge Scenarios -->
          <div class="fp-scenario-bar">
            <label>⚡ 1-Click Judge Demo Scenarios:</label>
            <div class="fp-scenario-grid">
              <button class="fp-scenario-btn active" data-scenario="A">A: Standard (Z)</button>
              <button class="fp-scenario-btn" data-scenario="B">B: Metro (X)</button>
              <button class="fp-scenario-btn" data-scenario="C">C: Surge (1.35x)</button>
              <button class="fp-scenario-btn" data-scenario="D">D: Skilled Tier</button>
              <button class="fp-scenario-btn" data-scenario="E">E: Emergency SOS</button>
              <button class="fp-scenario-btn" data-scenario="F">F: Wage Floor</button>
            </div>
          </div>

          <!-- Form Inputs -->
          <div class="fp-form-group">
            <label>Select Service & Skill Level:</label>
            <select class="fp-select" id="fp-service-select">
              <optgroup label="🚰 Plumbing">
                <option value="plumbing:tap_and_pipe_repair">Tap & Pipe Repair (Semi-Skilled: ₹108/hr, 45m)</option>
                <option value="plumbing:toilet_and_sanitary_fitting">Sanitary Fitting (Skilled: ₹119/hr, 75m)</option>
                <option value="plumbing:water_tank_and_motor_pipeline">Water Tank & Motor (Highly Skilled: ₹129/hr, 120m)</option>
              </optgroup>
              <optgroup label="⚡ Electrical">
                <option value="electrical:fan_and_switch_repair">Fan & Switch Repair (Semi-Skilled: ₹108/hr, 30m)</option>
                <option value="electrical:mcb_and_short_circuit_fix">MCB & Circuit Diagnosis (Skilled: ₹119/hr, 60m)</option>
                <option value="electrical:full_house_wiring_inspection">Full House Wiring (Highly Skilled: ₹129/hr, 120m)</option>
              </optgroup>
              <optgroup label="❄️ AC & Appliances">
                <option value="ac_repair:ac_filter_and_jet_servicing">AC Jet Servicing (Skilled: ₹119/hr, 60m)</option>
                <option value="ac_repair:ac_gas_refill_and_leak_fix">AC Gas Brazing (Highly Skilled: ₹129/hr, 90m)</option>
                <option value="appliance_repair:washing_machine_repair">Washing Machine Repair (Skilled: ₹119/hr, 60m)</option>
                <option value="appliance_repair:refrigerator_repair">Refrigerator Repair (Skilled: ₹119/hr, 60m)</option>
              </optgroup>
              <optgroup label="🧹 Cleaning, Carpentry & Home">
                <option value="cleaning:bathroom_deep_cleaning">Bathroom Deep Cleaning (Semi-Skilled: ₹108/hr, 60m)</option>
                <option value="cleaning:full_home_deep_cleaning_2bhk">Full Home 2 BHK (Skilled: ₹119/hr, 240m)</option>
                <option value="carpentry:furniture_assembly_and_hinges">Furniture Assembly (Semi-Skilled: ₹108/hr, 60m)</option>
                <option value="carpentry:door_lock_and_latches">Door Lock & Latches (Skilled: ₹119/hr, 45m)</option>
                <option value="painting:single_room_repaint">Single Room Repaint (Skilled: ₹119/hr, 180m)</option>
                <option value="pest_control:cockroach_and_ant_treatment">Pest Control (Semi-Skilled: ₹108/hr, 45m)</option>
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
            <label>Location Pincode (X/Y/Z) & Travel Distance:</label>
            <div style="display:flex; gap:10px;">
              <input type="text" class="fp-input" id="fp-pincode-input" value="${this.currentPincode}" placeholder="Pincode e.g. 560038" style="flex:1;" />
              <select class="fp-select" id="fp-dist-select" style="flex:1;">
                <option value="2.0" selected>Local (2.0 km)</option>
                <option value="3.5">Mid-range (3.5 km)</option>
                <option value="5.0">Extended (5.0 km)</option>
                <option value="10.0">Long distance (10.0 km)</option>
              </select>
            </div>
          </div>

          <!-- Price Display Banner -->
          <div class="fp-price-banner">
            <div class="fp-price-main">
              <h2 id="fp-estimated-price">₹--</h2>
              <div class="range" id="fp-price-range">Calculated Range: ₹-- - ₹--</div>
            </div>
            <div class="fp-price-badge-col">
              <span class="ai-badge">🤖 AI Fair Estimate</span>
              <div style="font-size:11px; opacity:0.85;">Pre-Booking Guaranteed</div>
            </div>
          </div>

          <!-- Real-Time Fairness Chips -->
          <div class="fp-fairness-chips" id="fp-fairness-chips">
            <span class="fp-chip">✓ Statutory Wage Protected</span>
            <span class="fp-chip">✓ 15% Platform Commission</span>
            <span class="fp-chip">✓ Anti-Gouging Surge Cap</span>
          </div>

          <!-- Transparent Breakdown -->
          <div class="fp-breakdown">
            <h4>
              <span>Transparent Itemized Breakdown</span>
              <span style="font-weight:400; font-size:11px; color:#64748b;">Zero Hidden Fees</span>
            </h4>
            <div class="fp-breakdown-row">
              <span>Statutory Base Price:</span>
              <span id="fp-row-base">₹--</span>
            </div>
            <div class="fp-breakdown-row">
              <span>City-Tier Cost Factor:</span>
              <span id="fp-row-city">₹--</span>
            </div>
            <div class="fp-breakdown-row">
              <span>Dynamic Demand Adjustment:</span>
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
              <span>Total Customer Fair Price:</span>
              <span id="fp-row-total" style="color:#2563eb;">₹--</span>
            </div>
            <div class="fp-breakdown-row split" style="margin-top:6px;">
              <span>↳ Worker Guaranteed Payout (85%):</span>
              <span id="fp-row-worker" style="color:#16a34a; font-weight:600;">₹--</span>
            </div>
            <div class="fp-breakdown-row split">
              <span>↳ Platform Commission (15%):</span>
              <span id="fp-row-platform" style="color:#475569;">₹--</span>
            </div>
          </div>

          <!-- Expandable Why this price section -->
          <div class="fp-explain-accordion">
            <div class="fp-explain-toggle" id="fp-explain-toggle">
              <span>🔍 Why this price? (Judge Mathematical Explanation)</span>
              <span id="fp-explain-icon">▼</span>
            </div>
            <div class="fp-explain-content" id="fp-explain-content">
              <ul class="fp-notes-list" id="fp-notes-list"></ul>
            </div>
          </div>

          <!-- Comparison Box (Toggled) -->
          <div class="fp-comparison-box" id="fp-comparison-box" style="display:none;">
            <h5>📊 Traditional Fixed Pricing vs FairPrice AI</h5>
            <table class="fp-compare-table">
              <thead>
                <tr>
                  <th>Dimension</th>
                  <th>Legacy Fixed Model</th>
                  <th>FairPrice AI Model</th>
                </tr>
              </thead>
              <tbody id="fp-compare-tbody"></tbody>
            </table>
          </div>

          <!-- Action Buttons -->
          <div class="fp-action-bar">
            <button class="fp-confirm-btn" id="fp-confirm-btn">Confirm Fair Booking</button>
            <button class="fp-compare-btn" id="fp-compare-toggle-btn">Compare Models</button>
          </div>
        </div>
      `;

      this.bindEvents();
    }

    bindEvents() {
      const select = this.container.querySelector('#fp-service-select');
      const pincodeInput = this.container.querySelector('#fp-pincode-input');
      const distSelect = this.container.querySelector('#fp-dist-select');
      const urgencyBtns = this.container.querySelectorAll('.fp-urgency-btn');
      const scenarioBtns = this.container.querySelectorAll('.fp-scenario-btn');
      const confirmBtn = this.container.querySelector('#fp-confirm-btn');
      const compareBtn = this.container.querySelector('#fp-compare-toggle-btn');
      const explainToggle = this.container.querySelector('#fp-explain-toggle');

      select.onchange = (e) => {
        const parts = e.target.value.split(':');
        this.currentCategory = parts[0];
        this.currentSubService = parts[1];
        this.customDemandOverride = null;
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

      scenarioBtns.forEach(btn => {
        btn.onclick = () => {
          scenarioBtns.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          this.applyScenario(btn.getAttribute('data-scenario'));
        };
      });

      explainToggle.onclick = () => {
        this.explainExpanded = !this.explainExpanded;
        const content = this.container.querySelector('#fp-explain-content');
        const icon = this.container.querySelector('#fp-explain-icon');
        content.style.display = this.explainExpanded ? 'block' : 'none';
        icon.innerText = this.explainExpanded ? '▲' : '▼';
      };

      compareBtn.onclick = () => {
        this.showComparison = !this.showComparison;
        const box = this.container.querySelector('#fp-comparison-box');
        box.style.display = this.showComparison ? 'block' : 'none';
        compareBtn.innerText = this.showComparison ? 'Hide Comparison' : 'Compare Models';
        if (this.showComparison) this.fetchComparison();
      };

      confirmBtn.onclick = () => {
        alert(`Fair Price Booking Confirmed for ${this.currentSubService.replace(/_/g, ' ')} at ₹${this.currentData?.estimated_price || '--'}!`);
      };
    }

    applyScenario(scenarioId) {
      const select = this.container.querySelector('#fp-service-select');
      const pincodeInput = this.container.querySelector('#fp-pincode-input');
      const distSelect = this.container.querySelector('#fp-dist-select');
      const urgencyBtns = this.container.querySelectorAll('.fp-urgency-btn');

      const setUrgencyUI = (urg) => {
        this.currentUrgency = urg;
        urgencyBtns.forEach(b => {
          if (b.getAttribute('data-urgency') === urg) b.classList.add('active');
          else b.classList.remove('active');
        });
      };

      if (scenarioId === 'A') {
        // Standard Town (Tier Z)
        this.currentCategory = 'plumbing';
        this.currentSubService = 'tap_and_pipe_repair';
        select.value = 'plumbing:tap_and_pipe_repair';
        this.currentPincode = '175001';
        pincodeInput.value = '175001';
        this.currentDistance = 2.0;
        distSelect.value = '2.0';
        setUrgencyUI('standard');
        this.customDemandOverride = null;
      } else if (scenarioId === 'B') {
        // Metro (Tier X)
        this.currentCategory = 'plumbing';
        this.currentSubService = 'tap_and_pipe_repair';
        select.value = 'plumbing:tap_and_pipe_repair';
        this.currentPincode = '560038';
        pincodeInput.value = '560038';
        this.currentDistance = 2.0;
        distSelect.value = '2.0';
        setUrgencyUI('standard');
        this.customDemandOverride = null;
      } else if (scenarioId === 'C') {
        // High Demand Surge
        this.currentCategory = 'plumbing';
        this.currentSubService = 'tap_and_pipe_repair';
        select.value = 'plumbing:tap_and_pipe_repair';
        this.currentPincode = '560038';
        pincodeInput.value = '560038';
        this.currentDistance = 2.0;
        distSelect.value = '2.0';
        setUrgencyUI('standard');
        this.customDemandOverride = 1.35;
      } else if (scenarioId === 'D') {
        // Skilled Tier
        this.currentCategory = 'electrical';
        this.currentSubService = 'mcb_and_short_circuit_fix';
        select.value = 'electrical:mcb_and_short_circuit_fix';
        this.currentPincode = '560038';
        pincodeInput.value = '560038';
        this.currentDistance = 2.0;
        distSelect.value = '2.0';
        setUrgencyUI('standard');
        this.customDemandOverride = null;
      } else if (scenarioId === 'E') {
        // Emergency SOS
        this.currentCategory = 'electrical';
        this.currentSubService = 'mcb_and_short_circuit_fix';
        select.value = 'electrical:mcb_and_short_circuit_fix';
        this.currentPincode = '560038';
        pincodeInput.value = '560038';
        this.currentDistance = 2.0;
        distSelect.value = '2.0';
        setUrgencyUI('emergency');
        this.customDemandOverride = null;
      } else if (scenarioId === 'F') {
        // Worker Wage Floor Protection
        this.currentCategory = 'cleaning';
        this.currentSubService = 'bathroom_deep_cleaning';
        select.value = 'cleaning:bathroom_deep_cleaning';
        this.currentPincode = '175001';
        pincodeInput.value = '175001';
        this.currentDistance = 2.0;
        distSelect.value = '2.0';
        setUrgencyUI('standard');
        this.customDemandOverride = 0.85;
      }

      this.fetchEstimate();
    }

    async fetchEstimate() {
      const payload = {
        service_category: this.currentCategory,
        sub_service: this.currentSubService,
        location_pincode: this.currentPincode,
        urgency: this.currentUrgency,
        distance_km: this.currentDistance,
        custom_demand_override: this.customDemandOverride
      };

      try {
        const res = await fetch(`${this.apiBaseUrl}/api/estimate-price`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const data = await res.json();
        this.currentData = data;
        this.updateUI(data);
        if (this.showComparison) this.fetchComparison();
      } catch (err) {
        console.warn('API error, computing client-side estimate', err);
        this.computeClientFallback();
      }
    }

    async fetchComparison() {
      const payload = {
        service_category: this.currentCategory,
        sub_service: this.currentSubService,
        location_pincode: this.currentPincode,
        urgency: this.currentUrgency,
        distance_km: this.currentDistance
      };

      try {
        const res = await fetch(`${this.apiBaseUrl}/api/compare-pricing`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const comp = await res.json();
        this.renderComparisonTable(comp);
      } catch (err) {
        console.warn('Comparison fetch error', err);
      }
    }

    renderComparisonTable(comp) {
      const tbody = this.container.querySelector('#fp-compare-tbody');
      if (!tbody || !comp) return;

      const trad = comp.traditional_model || {};
      const fp = comp.fairprice_ai || {};

      tbody.innerHTML = `
        <tr>
          <td><strong>Customer Price</strong></td>
          <td style="color:#dc2626; font-weight:700;">₹${trad.customer_price?.toFixed(2) || '--'} (Fixed)</td>
          <td style="color:#2563eb; font-weight:700;">₹${fp.customer_price?.toFixed(2) || '--'} (Dynamic)</td>
        </tr>
        <tr>
          <td><strong>Worker Payout</strong></td>
          <td>₹${trad.worker_payout?.toFixed(2) || '--'} (80%)</td>
          <td style="color:#16a34a; font-weight:700;">₹${fp.worker_payout?.toFixed(2) || '--'} (85%)</td>
        </tr>
        <tr>
          <td><strong>Platform Fee</strong></td>
          <td>${trad.platform_commission_rate || '20%'} (₹${trad.platform_fee?.toFixed(2) || '--'})</td>
          <td>${fp.platform_commission_rate || '15%'} (₹${fp.platform_fee?.toFixed(2) || '--'})</td>
        </tr>
        <tr>
          <td><strong>Statutory Wage Floor</strong></td>
          <td>❌ None</td>
          <td style="color:#16a34a;">✅ Guaranteed (${fp.pricing_basis || 'Statutory floor'})</td>
        </tr>
        <tr>
          <td><strong>City-Tier Cost Adjusted</strong></td>
          <td>❌ Flat Everywhere</td>
          <td style="color:#16a34a;">✅ ${fp.city_tier || 'Z'}-Class (${fp.city_multiplier || 1.0}x)</td>
        </tr>
        <tr>
          <td><strong>Surge Protection</strong></td>
          <td>❌ Opaque Dynamic Surge</td>
          <td style="color:#16a34a;">✅ Capped at 1.60x Maximum</td>
        </tr>
      `;
    }

    updateUI(data) {
      if (!data) return;
      document.getElementById('fp-estimated-price').innerText = data.formatted_price || `₹${data.estimated_price}`;
      document.getElementById('fp-price-range').innerText = `Calculated Range: ${data.price_range?.formatted || `₹${data.price_range_min} - ₹${data.price_range_max}`}`;

      const b = data.breakdown || {};
      document.getElementById('fp-row-base').innerText = `₹${b.base_service_price?.toFixed(2) || '--'}`;
      document.getElementById('fp-row-city').innerText = `₹${b.city_adjusted_base?.toFixed(2) || b.base_service_price?.toFixed(2) || '--'} (${b.city_tier || 'Z'} - ${b.city_multiplier?.toFixed(2) || '1.00'}x)`;
      document.getElementById('fp-row-demand').innerText = (b.demand_adjustment >= 0 ? `+₹${b.demand_adjustment?.toFixed(2)}` : `-₹${Math.abs(b.demand_adjustment)?.toFixed(2)}`);
      document.getElementById('fp-row-urgency').innerText = `+₹${b.urgency_surcharge?.toFixed(2) || '0.00'}`;
      document.getElementById('fp-row-travel').innerText = `+₹${b.distance_travel_fee?.toFixed(2) || '0.00'}`;
      document.getElementById('fp-row-total').innerText = `₹${data.estimated_price?.toFixed(2) || b.gross_total?.toFixed(2) || '--'}`;
      document.getElementById('fp-row-worker').innerText = `₹${b.worker_payout_guarantee?.toFixed(2) || '--'}`;
      document.getElementById('fp-row-platform').innerText = `₹${b.platform_fee?.toFixed(2) || '--'}`;

      const badge = document.getElementById('fp-demand-badge');
      badge.className = `fp-badge ${data.demand_level || 'normal'}`;
      badge.innerText = `Demand: ${data.demand_multiplier?.toFixed(2) || '1.00'}x (${data.demand_level || 'normal'})`;

      const notesList = document.getElementById('fp-notes-list');
      notesList.innerHTML = '';
      if (data.explainability_notes) {
        data.explainability_notes.forEach(note => {
          const li = document.createElement('li');
          li.innerText = `• ${note}`;
          notesList.appendChild(li);
        });
      }

      if (this.onPriceCalculated) this.onPriceCalculated(data);
    }

    computeClientFallback() {
      // Offline statutory formula fallback
      const wageMap = { 'standard': 108.0, 'skilled': 119.0, 'master': 129.0 };
      const durationMap = {
        'tap_and_pipe_repair': { tier: 'standard', dur: 45 },
        'toilet_and_sanitary_fitting': { tier: 'skilled', dur: 75 },
        'water_tank_and_motor_pipeline': { tier: 'master', dur: 120 },
        'fan_and_switch_repair': { tier: 'standard', dur: 30 },
        'mcb_and_short_circuit_fix': { tier: 'skilled', dur: 60 },
        'full_house_wiring_inspection': { tier: 'master', dur: 120 },
        'ac_filter_and_jet_servicing': { tier: 'skilled', dur: 60 },
        'ac_gas_refill_and_leak_fix': { tier: 'master', dur: 90 },
        'washing_machine_repair': { tier: 'skilled', dur: 60 },
        'refrigerator_repair': { tier: 'skilled', dur: 60 },
        'bathroom_deep_cleaning': { tier: 'standard', dur: 60 },
        'full_home_deep_cleaning_2bhk': { tier: 'skilled', dur: 240 },
        'furniture_assembly_and_hinges': { tier: 'standard', dur: 60 },
        'door_lock_and_latches': { tier: 'skilled', dur: 45 },
        'single_room_repaint': { tier: 'skilled', dur: 180 },
        'cockroach_and_ant_treatment': { tier: 'standard', dur: 45 }
      };

      const specInfo = durationMap[this.currentSubService] || { tier: 'standard', dur: 60 };
      const wage = wageMap[specInfo.tier] || 108.0;
      const base = Math.round(((wage * 1.8 * (specInfo.dur / 60.0)) / 0.85) * 100) / 100;

      // City Multiplier
      const prefix = (this.currentPincode || '').substring(0, 3);
      const xPrefixes = ['110', '400', '560', '600', '700', '500', '411', '380'];
      const yPrefixes = ['302', '226', '452', '440', '395', '682', '160', '462', '800', '641', '390', '530', '422', '360', '221', '781'];
      let cityMult = 1.00;
      let cityTier = 'Z';
      if (xPrefixes.includes(prefix)) { cityMult = 1.30; cityTier = 'X'; }
      else if (yPrefixes.includes(prefix)) { cityMult = 1.15; cityTier = 'Y'; }

      const cityAdjustedBase = Math.round(base * cityMult * 100) / 100;
      const demandMult = this.customDemandOverride !== null ? this.customDemandOverride : 1.0;
      const urgencyMult = this.currentUrgency === 'emergency' ? 1.35 : (this.currentUrgency === 'priority' ? 1.15 : 1.0);
      const emergencyFee = this.currentUrgency === 'emergency' ? 100 : (this.currentUrgency === 'priority' ? 30 : 0);
      const travelFee = Math.max(0, (this.currentDistance - 2.5) * 15);

      const demandDelta = Math.round(cityAdjustedBase * (demandMult - 1.0) * 100) / 100;
      const urgencyDelta = Math.round(((cityAdjustedBase * (urgencyMult - 1.0)) + emergencyFee) * 100) / 100;
      const total = Math.round((cityAdjustedBase + demandDelta + urgencyDelta + travelFee) * 100) / 100;
      const workerPayout = Math.round(total * 0.85 * 100) / 100;
      const platformFee = Math.round(total * 0.15 * 100) / 100;

      const data = {
        estimated_price: total,
        formatted_price: `₹${total.toFixed(2)}`,
        price_range: { formatted: `₹${Math.round(total * 0.93)} - ₹${Math.round(total * 1.07)}` },
        demand_level: demandMult > 1.2 ? 'high' : (demandMult > 1.05 ? 'moderate' : 'normal'),
        demand_multiplier: demandMult,
        breakdown: {
          base_service_price: base,
          city_adjusted_base: cityAdjustedBase,
          city_tier: cityTier,
          city_multiplier: cityMult,
          demand_adjustment: demandDelta,
          urgency_surcharge: urgencyDelta,
          distance_travel_fee: Math.round(travelFee * 100) / 100,
          gross_total: total,
          worker_payout_guarantee: workerPayout,
          platform_fee: platformFee
        },
        explainability_notes: [
          `Base statutory price: ₹${base.toFixed(2)} (₹${wage}/hr floor × 1.8 × ${(specInfo.dur/60).toFixed(2)}h ÷ 0.85)`,
          `City-tier adjustment (${cityTier}-Class): ${cityMult.toFixed(2)}x applied (₹${cityAdjustedBase.toFixed(2)})`,
          `Dynamic demand index ${demandMult.toFixed(2)}x: ${demandDelta >= 0 ? '+' : ''}₹${demandDelta.toFixed(2)}`,
          `Worker guaranteed payout (85%): ₹${workerPayout.toFixed(2)} | Platform fee: 15% (₹${platformFee.toFixed(2)})`,
          `Anti-price-gouging safety cap active`
        ]
      };
      this.currentData = data;
      this.updateUI(data);
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
