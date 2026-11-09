import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../theme/tokens.dart';
import '../studio/convert_tool.dart';
import '../studio/merge_tool.dart';
import '../studio/studio_state.dart';
import '../studio/studio_widgets.dart';
import '../studio/wave_tool.dart';
import '../widgets/controls.dart';
import '../widgets/page.dart';
import '../widgets/tappable.dart';
import 'settings_screen.dart';

/// Opens a Studio tool on the Studio tab.
void openStudioTool(BuildContext context, String id) {
  final nav = AppScope.of(context).nav;
  StudioState.instance.stopPreview();
  nav.setNowPlaying(false);
  nav.push(
    CupertinoPageRoute<void>(builder: (_) => StudioToolPage(tool: toolById(id))),
    on: AppTab.studio,
  );
}

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    return ListenableBuilder(
      listenable: app.jobs,
      builder: (context, _) {
        final hist = app.jobs.history.take(6).toList();
        return LargeTitlePage(
          title: 'Audio Studio',
          showBack: false,
          background: t.groupedBg,
          actions: [
            GlassCircleButton(
              icon: CupertinoIcons.person_crop_circle,
              label: 'Settings',
              iconSize: 22,
              onTap: () => showSettingsSheet(context),
            ),
          ],
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Text(
                  'Edit, trim, and convert audio files on your Windows PC. Powered by native high-performance FFmpeg.',
                  style: t.subhead.copyWith(color: t.secondary),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 600;
                    return isWide
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WORKSTATION TOOLS', style: t.caption1.copyWith(fontWeight: FontWeight.bold, color: t.secondary)),
                              const SizedBox(height: 10),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 2.4,
                                children: [
                                  for (final x in studioTools)
                                    _DesktopStudioCard(
                                      tool: x,
                                      icon: toolStyle(x.id).$1,
                                      color: toolStyle(x.id).$2,
                                      onTap: () => openStudioTool(context, x.id),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : InsetGroup(
                            header: 'Tools',
                            children: [
                              for (final x in studioTools)
                                InsetRow(
                                  leading: IconTile(toolStyle(x.id).$1, color: toolStyle(x.id).$2, size: 34),
                                  title: x.title,
                                  subtitle: x.desc,
                                  chevron: true,
                                  minHeight: 62,
                                  onTap: () => openStudioTool(context, x.id),
                                ),
                            ],
                          );
                  },
                ),
              ),
            ),
            if (hist.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: InsetGroup(
                    header: 'Recent Exports (Saved in Music\\Astra Music)',
                    children: [
                      for (final h in hist)
                        InsetRow(
                          leading: const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: Color(0xFF34C759),
                            size: 28,
                          ),
                          title: h.title,
                          subtitle: h.sub,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DesktopStudioCard extends StatelessWidget {
  const _DesktopStudioCard({
    required this.tool,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final StudioTool tool;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      label: tool.title,
      press: Press.scale,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.cell,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.separator.withValues(alpha: .2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: t.dark ? .3 : .05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: .7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tool.title, maxLines: 1, style: t.headline.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(tool.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.caption1.copyWith(color: t.secondary)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, size: 18, color: t.tertiary),
          ],
        ),
      ),
    );
  }
}

/// A single Studio tool on its own page.
class StudioToolPage extends StatelessWidget {
  const StudioToolPage({super.key, required this.tool});
  final StudioTool tool;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return LargeTitlePage(
      title: tool.title,
      largeTitle: false,
      background: t.groupedBg,
      slivers: [
        SliverToBoxAdapter(
          child: switch (tool.kind) {
            'wave' => WaveTool(tool: tool),
            'conv' => ConvertTool(tool: tool),
            _ => const MergeTool(),
          },
        ),
      ],
    );
  }
}
