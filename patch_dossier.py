import re

with open('lib/features/dossier/dossier_screen.dart', 'r') as f:
    content = f.read()

# 1. 360 card subtitle
content = content.replace(
    "Text('Explore the estate in immersive panorama',",
    "Text('Watch the full estate video tour',",
    1
)

# 2. AR card subtitle
content = content.replace(
    "Text('See the estate in your surroundings',",
    "Text('Swipe left to explore the estate panorama',",
    1
)

# 3. AR card title
old = "Text('AR PREVIEW',"
new = "Text('PANORAMA TOUR',"
content = content.replace(old, new, 1)

# 4. Replace _show360Tour with YouTube iframe version
old_360 = '''  void _show360Tour(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: AtithyaColors.obsidian.withValues(alpha: 0.95),
      builder: (context) => Scaffold(
        backgroundColor: AtithyaColors.obsidian,
        body: Stack(
          children: [
            // Panoramic scroll simulation (full-screen swipeable image with horizontal overflow)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: kIsWeb ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
                      child: Row(
                        children: _getImages().expand((url) => [
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            height: 300,
                            width: MediaQuery.of(context).size.width,
                            placeholder: (_, __) => Container(
                                width: MediaQuery.of(context).size.width,
                                color: AtithyaColors.darkSurface),
                            errorWidget: (_, __, ___) => Container(
                                width: MediaQuery.of(context).size.width,
                                color: AtithyaColors.darkSurface),
                          ),
                        ]).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('DRAG TO EXPLORE',
                      style: AtithyaTypography.labelMicro.copyWith(
                          color: AtithyaColors.imperialGold, letterSpacing: 4)),
                  const SizedBox(height: 8),
                  Text('← Swipe horizontally for panoramic view →',
                      style: AtithyaTypography.caption),
                ],
              ),
            ),
            // Close button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AtithyaColors.darkSurface,
                        border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.3))),
                    child: const Icon(Icons.close, color: AtithyaColors.pearl, size: 18),
                  ),
                ),
              ),
            ),
            // VR frame overlay
            IgnorePointer(
              child: Center(
                child: Container(
                  width: double.infinity, height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    children: [
                      // Corner markers
                      Positioned(top: 8, left: 8, child: _vrCorner()),
                      Positioned(top: 8, right: 8, child: Transform.flip(flipX: true, child: _vrCorner())),
                      Positioned(bottom: 8, left: 8, child: Transform.flip(flipY: true, child: _vrCorner())),
                      Positioned(bottom: 8, right: 8, child: Transform.flip(flipX: true, flipY: true, child: _vrCorner())),
                      // Center crosshair
                      Center(
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AtithyaColors.imperialGold.withValues(alpha: 0.6), width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }'''

new_360 = '''  void _show360Tour(BuildContext context) {
    final videoId = (widget.estate['videoId360'] as String?)?.trim();
    if (videoId == null || videoId.isEmpty) return;
    final viewId = 'yt-$videoId-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
        return html.IFrameElement()
          ..src = 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&fs=1'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true
          ..setAttribute('allow', 'autoplay; fullscreen; accelerometer; gyroscope; picture-in-picture');
      });
    }
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogCtx) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // YouTube iframe
            if (kIsWeb)
              HtmlElementView(viewType: viewId)
            else
              const Center(
                child: Text('360° video available on web',
                    style: TextStyle(color: Colors.white)),
              ),
            // Close button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogCtx),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.7),
                      border: Border.all(
                          color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }'''

# Normalize whitespace in old_360 for matching
# Find and replace using a more flexible approach
import re as re_mod
# Use a regex that handles any whitespace variation in the function
start_marker = '  void _show360Tour(BuildContext context) {'
end_marker_after = '  Widget _vrCorner()'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker_after)

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_360 + '\n\n' + content[end_idx:]
    print("_show360Tour replaced successfully")
else:
    print(f"ERROR: Could not find _show360Tour. start={start_idx}, end={end_idx}")

# 5. Replace _showARPreview with panoramic image scroll version
old_ar_start = '  void _showARPreview(BuildContext context) {'
new_ar = '''  void _showARPreview(BuildContext context) {
    final panorama = (widget.estate['panoramaImage'] as String?) ?? '';
    final images = _getImages();
    // Use panoramaImage if available (wider source), else tile all estate images side by side
    final urls = (panorama.isNotEmpty)
        ? List.filled(3, panorama)   // repeat 3x for continuous pan feel
        : images;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogCtx) {
        final screenW = MediaQuery.of(dialogCtx).size.width;
        final screenH = MediaQuery.of(dialogCtx).size.height;
        // Each image tile is 2.2x screen width when using panoramaImage, 1.1x otherwise
        final tileW = panorama.isNotEmpty ? screenW * 2.2 : screenW * 1.1;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full-screen horizontal panorama scroll
              SizedBox(
                width: screenW,
                height: screenH,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: kIsWeb
                      ? const ClampingScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Row(
                    children: urls.map((url) => CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      height: screenH,
                      width: tileW,
                      placeholder: (_, __) => Container(
                        width: tileW,
                        color: AtithyaColors.darkSurface,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: tileW,
                        color: AtithyaColors.darkSurface,
                      ),
                    )).toList(),
                  ),
                ),
              ),
              // VR-style corner markers overlay
              IgnorePointer(
                child: Stack(children: [
                  Positioned(top: 48, left: 24, child: _vrCorner()),
                  Positioned(
                      top: 48,
                      right: 24,
                      child: Transform.flip(flipX: true, child: _vrCorner())),
                  Positioned(
                      bottom: 80,
                      left: 24,
                      child: Transform.flip(flipY: true, child: _vrCorner())),
                  Positioned(
                      bottom: 80,
                      right: 24,
                      child: Transform.flip(
                          flipX: true, flipY: true, child: _vrCorner())),
                ]),
              ),
              // Bottom label
              Positioned(
                bottom: 32, left: 0, right: 0,
                child: Column(
                  children: [
                    Text('← DRAG TO EXPLORE PANORAMA →',
                        textAlign: TextAlign.center,
                        style: AtithyaTypography.labelMicro.copyWith(
                            color: AtithyaColors.imperialGold, letterSpacing: 4)),
                    const SizedBox(height: 6),
                    Text('Swipe horizontally for 360° estate view',
                        textAlign: TextAlign.center,
                        style: AtithyaTypography.caption),
                  ],
                ),
              ),
              // Close button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.7),
                        border: Border.all(
                            color: AtithyaColors.imperialGold.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }'''

ar_start_idx = content.find(old_ar_start)
# Find the _vrCorner Widget definition to know where _showARPreview ends
vrCorner_widget = '  Widget _vrCorner()'
ar_end_idx = content.find(vrCorner_widget, ar_start_idx)

if ar_start_idx != -1 and ar_end_idx != -1:
    content = content[:ar_start_idx] + new_ar + '\n\n' + content[ar_end_idx:]
    print("_showARPreview replaced successfully")
else:
    print(f"ERROR: Could not find _showARPreview. start={ar_start_idx}, end={ar_end_idx}")

# 6. Remove _ARGridPainter class (no longer needed)
ar_painter_marker = '\n// AR grid painter\nclass _ARGridPainter extends CustomPainter {'
ar_painter_end_marker = '  @override bool shouldRepaint(_) => false;\n}\n'
ap_start = content.find(ar_painter_marker)
if ap_start != -1:
    ap_end = content.find(ar_painter_end_marker, ap_start)
    if ap_end != -1:
        content = content[:ap_start] + content[ap_end + len(ar_painter_end_marker):]
        print("_ARGridPainter removed")
    else:
        print("WARNING: Could not find end of _ARGridPainter")
else:
    print("WARNING: _ARGridPainter not found (may already be removed)")

with open('lib/features/dossier/dossier_screen.dart', 'w') as f:
    f.write(content)

print("Done!")
