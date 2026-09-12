# ==============================================================================
# Dockerfile for Flutter (Android Build & Dev Environment)
# ==============================================================================
# Base image includes:
# - Flutter SDK (stable channel)
# - Android SDK & command-line tools
# - OpenJDK 17
# ==============================================================================
FROM ghcr.io/cirruslabs/flutter:stable

# Prevent git directory ownership warnings inside container
RUN git config --global --add safe.directory /app

# Accept Android SDK licenses automatically
RUN yes | flutter doctor --android-licenses || true

# Configure workspace
WORKDIR /app

# Verify installation during image build
RUN flutter doctor -v

CMD ["bash"]
