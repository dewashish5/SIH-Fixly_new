import React, { useState, useEffect } from 'react';

// Reusable components matching Flutter AppTheme
const Button = ({ children, variant = 'elevated', disabled, className = '', ...props }) => {
  const baseStyles = 'inline-flex items-center justify-center font-semibold transition-colors duration-200 rounded-md min-h-[52px] px-6 w-full sm:w-auto text-[15px]';
  const variants = {
    elevated: 'bg-primary-500 text-white hover:bg-primary-600 disabled:bg-primary-500/40 disabled:text-white/80 shadow-sm shadow-primary-500/20',
    outlined: 'border border-primary-500 text-primary-500 hover:bg-primary-50 disabled:border-primary-500/40 disabled:text-primary-500/40 dark:hover:bg-primary-500/10',
    text: 'text-primary-500 hover:bg-primary-50 disabled:text-primary-500/40 dark:hover:bg-primary-500/10'
  };

  return (
    <button
      className={`${baseStyles} ${variants[variant]} ${className}`}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

const Card = ({ children, className = '' }) => (
  <div className={`bg-surface-card border border-surface-border rounded-[16px] shadow-card overflow-hidden ${className}`}>
    {children}
  </div>
);

const Input = ({ placeholder, error, className = '', ...props }) => {
  return (
    <div className="w-full">
      <input
        placeholder={placeholder}
        className={`w-full bg-surface-card border border-surface-border rounded-md px-4 py-3 text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow ${
          error ? 'border-status-error focus:ring-status-error focus:border-status-error' : ''
        } ${className}`}
        {...props}
      />
      {error && <p className="mt-1 text-sm text-status-error">{error}</p>}
    </div>
  );
};

const Chip = ({ children, selected, disabled, onClick, className = '' }) => (
  <button
    onClick={onClick}
    disabled={disabled}
    className={`inline-flex items-center px-3 py-1.5 rounded-md text-sm font-medium border transition-colors ${
      selected 
        ? 'bg-primary-50 border-primary-50 text-primary-900 dark:bg-primary-800 dark:border-primary-800 dark:text-primary-100'
        : 'bg-surface-card border-surface-border text-text-secondary hover:bg-surface-subtle dark:hover:bg-surface-subtle disabled:opacity-50'
    } ${className}`}
  >
    {children}
  </button>
);

const Switch = ({ checked, onChange }) => (
  <button
    type="button"
    role="switch"
    aria-checked={checked}
    onClick={() => onChange(!checked)}
    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
      checked ? 'bg-primary-500/35' : 'bg-surface-border'
    }`}
  >
    <span
      className={`inline-block h-4 w-4 transform rounded-full transition-transform ${
        checked ? 'translate-x-6 bg-primary-500' : 'translate-x-1 bg-text-muted'
      }`}
    />
  </button>
);

export default function ThemeShowcase() {
  const [isDark, setIsDark] = useState(false);
  const [selectedChip, setSelectedChip] = useState('All');
  const [switchOn, setSwitchOn] = useState(true);

  // Toggle dark mode on the document element
  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDark]);

  return (
    <div className="min-h-screen bg-surface-app text-text-primary p-6 md:p-10 transition-colors duration-300">
      <div className="max-w-5xl mx-auto space-y-12">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Theme Showcase</h1>
            <p className="text-text-secondary mt-1">Responsive screen demonstrating the Fixly React components.</p>
          </div>
          <div className="flex items-center gap-3 bg-surface-card px-4 py-2 rounded-lg border border-surface-border shadow-sm">
            <span className="text-sm font-medium">Dark Mode</span>
            <Switch checked={isDark} onChange={setIsDark} />
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Colors Section */}
          <section className="space-y-6">
            <h2 className="text-xl font-semibold border-b border-surface-border pb-2">Colors</h2>
            
            <div className="space-y-4">
              <div>
                <h3 className="text-sm font-medium text-text-muted mb-2 uppercase tracking-wider">Primary Scale</h3>
                <div className="flex h-12 rounded-lg overflow-hidden shadow-sm">
                  <div className="flex-1 bg-primary-50"></div>
                  <div className="flex-1 bg-primary-200"></div>
                  <div className="flex-1 bg-primary-400"></div>
                  <div className="flex-1 bg-primary-500 flex items-center justify-center text-white text-xs font-bold">500</div>
                  <div className="flex-1 bg-primary-700"></div>
                  <div className="flex-1 bg-primary-900"></div>
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium text-text-muted mb-2 uppercase tracking-wider">Accent Scale</h3>
                <div className="flex h-12 rounded-lg overflow-hidden shadow-sm">
                  <div className="flex-1 bg-accent-50"></div>
                  <div className="flex-1 bg-accent-200"></div>
                  <div className="flex-1 bg-accent-400"></div>
                  <div className="flex-1 bg-accent-500 flex items-center justify-center text-white text-xs font-bold">500</div>
                  <div className="flex-1 bg-accent-700"></div>
                  <div className="flex-1 bg-accent-900"></div>
                </div>
              </div>
            </div>
          </section>

          {/* Typography Section */}
          <section className="space-y-6">
            <h2 className="text-xl font-semibold border-b border-surface-border pb-2">Typography</h2>
            <div className="space-y-4 bg-surface-card p-6 rounded-[16px] border border-surface-border">
              <div>
                <h1 className="text-4xl font-extrabold tracking-tight">Display Large</h1>
                <p className="text-text-muted text-sm mt-1">4xl / extrabold / tracking-tight</p>
              </div>
              <div>
                <h2 className="text-2xl font-bold">Heading Medium</h2>
                <p className="text-text-muted text-sm mt-1">2xl / bold</p>
              </div>
              <div>
                <p className="text-base text-text-primary">Body regular text showing standard reading weight and color. It should be legible on both light and dark backgrounds.</p>
              </div>
              <div>
                <p className="text-sm text-text-secondary font-medium">Secondary muted text for labels and captions.</p>
              </div>
            </div>
          </section>
        </div>

        {/* Components Section */}
        <section className="space-y-6">
          <h2 className="text-xl font-semibold border-b border-surface-border pb-2">Components</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Buttons */}
            <Card className="p-6 space-y-6">
              <h3 className="text-lg font-semibold">Buttons</h3>
              <div className="space-y-4">
                <Button variant="elevated">Elevated Button</Button>
                <Button variant="outlined">Outlined Button</Button>
                <Button variant="text">Text Button</Button>
                <Button variant="elevated" disabled>Disabled Button</Button>
              </div>
            </Card>

            {/* Inputs & Controls */}
            <Card className="p-6 space-y-6">
              <h3 className="text-lg font-semibold">Inputs & Controls</h3>
              <div className="space-y-4">
                <Input placeholder="Standard Input" />
                <Input placeholder="Input with Error" error="This field is required." />
                
                <div className="pt-4 space-y-3">
                  <h4 className="text-sm font-medium text-text-secondary">Chips</h4>
                  <div className="flex flex-wrap gap-2">
                    {['All', 'Active', 'Pending'].map(label => (
                      <Chip 
                        key={label}
                        selected={selectedChip === label}
                        onClick={() => setSelectedChip(label)}
                      >
                        {label}
                      </Chip>
                    ))}
                    <Chip disabled>Disabled</Chip>
                  </div>
                </div>

                <div className="pt-4 flex items-center justify-between">
                  <span className="text-sm font-medium text-text-secondary">Toggle Switch</span>
                  <Switch checked={switchOn} onChange={setSwitchOn} />
                </div>
              </div>
            </Card>
          </div>
        </section>

        {/* Complex Example Card */}
        <section className="space-y-6">
          <h2 className="text-xl font-semibold border-b border-surface-border pb-2">Complex Example</h2>
          
          <Card className="p-0 max-w-2xl mx-auto">
            <div className="p-6 border-b border-surface-border">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-primary-100 dark:bg-primary-800 rounded-full flex items-center justify-center text-primary-600 dark:text-primary-300 font-bold text-lg">
                    FX
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Service Request</h3>
                    <p className="text-text-secondary text-sm">Created 2 hours ago</p>
                  </div>
                </div>
                <span className="px-3 py-1 bg-status-pending-bg text-status-pending-text text-xs font-semibold rounded-full">
                  In Progress
                </span>
              </div>
              <p className="text-text-primary">
                Customer needs a complete inspection of their central heating system. Please ensure all safety protocols are followed and parts are documented.
              </p>
            </div>
            <div className="bg-surface-subtle p-6 flex justify-end gap-3 rounded-b-[16px]">
              <Button variant="text" className="!min-h-[40px] px-4">Decline</Button>
              <Button variant="elevated" className="!min-h-[40px] px-4">Accept Request</Button>
            </div>
          </Card>
        </section>

      </div>
    </div>
  );
}
