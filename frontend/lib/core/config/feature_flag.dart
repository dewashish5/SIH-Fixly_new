/// Global feature flags configuration
class FeatureFlags {
  FeatureFlags._();

  /// Set to true to enable mock worker (Vaibhav Jain) simulation over Socket.io.
  /// When false, the worker simulation is completely disabled and does not connect or consume resources.
  static bool enableMockWorkerSimulation = true;
}

/// Shorthand getter for easy access
bool get kEnableMockWorkerSimulation => FeatureFlags.enableMockWorkerSimulation;
