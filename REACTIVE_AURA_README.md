# Reactive Fluid Aura Component

A beautiful, animated energy aura that reacts to audio amplitude, perfect for creating an immersive coaching experience with Lumi.

## Features

- **Swirling Animation**: 4 overlapping circles that move in fluid, organic patterns using sine/cosine functions
- **Audio Reactivity**: Aura intensity and blur radius respond to audio volume/amplitude
- **Performance Optimized**: Uses RepaintBoundary and limited circle count for 60 FPS on older devices
- **Smooth Transitions**: Tween-based volume smoothing prevents flickering
- **Customizable**: Easy to integrate with any avatar image and audio source

## Usage

```dart
ReactiveAuraWidget(
  lumiImageUrl: 'https://example.com/lumi-avatar.png',
  audioUrl: 'https://example.com/lumi-voice.mp3', // Optional
)
```

## Architecture

### Layer Stack
```
Stack
├── CustomPaint (AuraPainter) - Animated aura background
└── Image.network - Lumi avatar (static foreground)
```

### AuraPainter Logic
- **4 Circles**: Overlapping radial gradients with MaskFilter.blur
- **Swirling Motion**: Centers shift using sin/cos functions driven by AnimationController
- **Volume Response**: Blur radius and circle scale multiply by volume (0.0-1.0)
- **Gradient**: Colors.amber.withOpacity(0.6) → Colors.transparent

### Audio Integration
- **Package**: audioplayers for playback
- **Reactivity**: Simulated volume changes based on playback position (can be enhanced with noise_meter for real amplitude)
- **Smoothing**: Built-in state updates prevent jarring transitions

### Performance
- **RepaintBoundary**: Prevents unnecessary repaints of surrounding UI
- **Anti-aliasing**: Enabled for smooth circle edges
- **Limited Circles**: 4 circles maximum for optimal performance
- **Efficient Repaints**: Only repaints when animation or volume changes

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  audioplayers: ^6.0.0
```

## Future Enhancements

- Real audio amplitude detection using noise_meter package
- Multiple aura colors/themes
- Particle effects for enhanced visual appeal
- GPU-accelerated rendering for even smoother animations